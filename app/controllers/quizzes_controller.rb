class QuizzesController < ApplicationController
  before_action :set_lesson

  ROUND_SIZE = 10

  # Renders the current question of an in-progress round, a fresh round, the
  # end-of-round summary, or an "all caught up" state.
  def show
    QuizQuestion.sync_for(@lesson)
    @progress = @lesson.progress_for(current_user)
    round = current_round

    if round && round["pos"].to_i >= round["ids"].size
      # Round just finished — show the summary once, then clear it so the next
      # visit starts a new round.
      @correct = round["correct"].to_i
      @answered = round["ids"].size
      session.delete(round_key)
      return render :summary
    end

    round ||= start_round
    return render :empty if round.nil?

    @question = QuizQuestion.find(round["ids"][round["pos"]])
    @position = round["pos"] + 1
    @count = round["ids"].size
  end

  # Grades one answer, updates the Leitner schedule, advances the round, and
  # shows per-question feedback with a link to the next question.
  def answer
    round = current_round
    return redirect_to lesson_quiz_path(@lesson) if round.nil?

    @question = QuizQuestion.find(params[:question_id])

    # Ignore stale or out-of-order submissions.
    return redirect_to lesson_quiz_path(@lesson) if round["ids"][round["pos"]] != @question.id

    @choice = params[:choice].to_s
    @correct = @choice.casecmp?(@question.answer)

    review = QuizReview.find_or_initialize_by(user: current_user, quiz_question: @question)
    review.record_answer(correct: @correct)

    round["pos"] += 1
    round["correct"] += 1 if @correct
    session[round_key] = round

    @last = round["pos"] >= round["ids"].size
    @progress = @lesson.progress_for(current_user)
  end

  # Abandon the current round and return to the lesson.
  def reset
    session.delete(round_key)
    redirect_to lesson_path(@lesson)
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:lesson_id])
  end

  def round_key
    "quiz_round_lesson_#{@lesson.id}"
  end

  def current_round
    session[round_key]
  end

  # Builds and stores a new round: items due for review first, then unseen
  # questions, capped at ROUND_SIZE. Returns nil when nothing needs reviewing.
  def start_round
    ids = build_queue
    return nil if ids.empty?

    session[round_key] = { "ids" => ids, "pos" => 0, "correct" => 0 }
  end

  def build_queue
    question_ids = @lesson.quiz_questions.pluck(:id)
    return [] if question_ids.empty?

    reviews = QuizReview.where(user: current_user, quiz_question_id: question_ids)
    reviewed_ids = reviews.pluck(:quiz_question_id)

    due_ids = reviews.due.order(:due_at).pluck(:quiz_question_id)
    unseen_ids = question_ids - reviewed_ids

    (due_ids + unseen_ids.shuffle).first(ROUND_SIZE)
  end
end
