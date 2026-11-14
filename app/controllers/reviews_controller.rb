# One daily review across every lesson the learner has started: the words that
# are most overdue first, then a few new ones from the current lesson.
class ReviewsController < ApplicationController
  ROUND_SIZE = 20
  NEW_WORDS = 3
  ROUND_KEY = "daily_review_round".freeze

  def show
    round = session[ROUND_KEY]

    if round && round["pos"].to_i >= round["ids"].size
      @correct = round["correct"].to_i
      @answered = round["ids"].size
      session.delete(ROUND_KEY)
      @forecast = QuizReview.forecast_for(current_user)
      return render :summary
    end

    round ||= start_round
    if round.nil?
      @forecast = QuizReview.forecast_for(current_user)
      return render :empty
    end

    @question = QuizQuestion.includes(:lesson).find_by(id: round["ids"][round["pos"]])
    return skip_unavailable(round) unless @question && still_wanted?(round)

    @position = round["pos"] + 1
    @count = round["ids"].size
    @say_it = QuizReview.say_it?(current_user, @question)
  end

  def answer
    round = session[ROUND_KEY]
    return redirect_to review_path if round.nil?

    @question = QuizQuestion.find_by(id: params[:question_id])
    return redirect_to review_path if @question.nil? || round["ids"][round["pos"]] != @question.id

    review = QuizReview.find_or_initialize_by(user: current_user, quiz_question: @question)
    rating = params[:rating].to_s.to_sym
    if QuizReview::RATINGS.key?(rating)
      # A "Say it" card: the learner marks themselves, nothing is graded for them.
      @self_rated = true
      @correct = rating != :again
      review.record_answer(correct: @correct, rating: rating)
    else
      @choice = params[:choice].to_s
      @correct = @choice.casecmp?(@question.answer)
      review.record_answer(correct: @correct)
    end

    round["pos"] += 1
    round["correct"] += 1 if @correct
    session[ROUND_KEY] = round
    @last = round["pos"] >= round["ids"].size
  end

  def reset
    session.delete(ROUND_KEY)
    redirect_to root_path
  end

  private

  # A word the learner has answered elsewhere since the round began (for
  # example in a lesson quiz) is skipped, so FSRS isn't run on it early.
  def still_wanted?(round)
    review = QuizReview.find_by(user: current_user, quiz_question_id: @question.id)
    review.nil? || review.due_at.nil? || review.due_at <= Time.current
  end

  def skip_unavailable(round)
    round["pos"] += 1
    session[ROUND_KEY] = round
    redirect_to review_path
  end

  def start_round
    ids = build_queue
    return nil if ids.empty?

    session[ROUND_KEY] = { "ids" => ids, "pos" => 0, "correct" => 0 }
  end

  def build_queue
    visible = Lesson.visible_to(current_user).select(:id)
    due_ids = QuizReview.due.where(user: current_user)
                        .joins(:quiz_question).where(quiz_questions: { lesson_id: visible })
                        .order(:due_at).limit(ROUND_SIZE).pluck(:quiz_question_id)
    due_ids += new_ids(ROUND_SIZE - due_ids.size) if due_ids.size < ROUND_SIZE
    due_ids.first(ROUND_SIZE)
  end

  # A few unseen questions from the lesson the learner is on, only on top of due
  # words and never more than NEW_WORDS.
  def new_ids(room)
    lesson = DailyPath.new(current_user).current_lesson
    return [] unless lesson

    QuizQuestion.sync_for(lesson)
    seen = QuizReview.where(user: current_user).select(:quiz_question_id)
    lesson.quiz_questions.where.not(id: seen).pluck(:id).shuffle.first([ room, NEW_WORDS ].min)
  end
end
