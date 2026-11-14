require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
    QuizQuestion.sync_for(@lesson)
  end

  test "requires sign in" do
    get review_path
    assert_redirected_to new_session_path
  end

  test "draws the most overdue words and no more than the round size" do
    sign_in_as(@user)
    questions = @lesson.quiz_questions.order(:id).to_a
    older, newer = questions.first, questions.second
    QuizReview.create!(user: @user, quiz_question: newer, box: 2, fsrs_state: 2, stability: 1.0, difficulty: 5.0, due_at: 1.hour.ago)
    QuizReview.create!(user: @user, quiz_question: older, box: 2, fsrs_state: 2, stability: 1.0, difficulty: 5.0, due_at: 2.days.ago)

    get review_path
    assert_response :success
    assert_match(/value="#{older.id}"/, response.body)
    assert_operator session[ReviewsController::ROUND_KEY]["ids"].size, :<=, ReviewsController::ROUND_SIZE
  end

  test "words from other lessons are included" do
    sign_in_as(@user)
    other = Lesson.create!(number: 99, title: "Other", lesson_type: "curriculum")
    other.vocabulary_items.create!(irish: "bó", english: "cow")
    QuizQuestion.sync_for(other)
    question = other.quiz_questions.first
    QuizReview.create!(user: @user, quiz_question: question, box: 2, fsrs_state: 2, stability: 1.0, difficulty: 5.0, due_at: 1.day.ago)

    get review_path
    assert_includes session[ReviewsController::ROUND_KEY]["ids"], question.id
  end

  test "new words are added only up to the cap" do
    sign_in_as(@user)
    get review_path
    assert_operator session[ReviewsController::ROUND_KEY]["ids"].size, :<=, ReviewsController::NEW_WORDS
  end

  test "answering schedules the word and a finished round shows the forecast" do
    sign_in_as(@user)
    get review_path
    id = session[ReviewsController::ROUND_KEY]["ids"].first
    question = QuizQuestion.find(id)

    assert_difference -> { ReviewLog.count }, 1 do
      post answer_review_path, params: { question_id: id, choice: question.answer }
    end
    assert_response :success
    assert QuizReview.find_by(user: @user, quiz_question: question).due_at.present?

    session_round = session[ReviewsController::ROUND_KEY]
    (session_round["ids"].size - 1).times do
      get review_path
      q = QuizQuestion.find(session[ReviewsController::ROUND_KEY]["ids"][session[ReviewsController::ROUND_KEY]["pos"]])
      post answer_review_path, params: { question_id: q.id, choice: q.answer }
    end
    get review_path
    assert_match(/Round complete/, response.body)
    assert_match(/Tomorrow: \d+ · This week: \d+/, response.body)
  end

  test "nothing due and no new words shows the caught-up state" do
    sign_in_as(users(:admin))
    get review_path
    assert_response :success
  end

  test "reset clears the round" do
    sign_in_as(@user)
    get review_path
    delete reset_review_path
    assert_redirected_to root_path
    assert_nil session[ReviewsController::ROUND_KEY]
  end

  test "answering a question outside the round redirects without recording" do
    sign_in_as(@user)
    get review_path
    ids = session[ReviewsController::ROUND_KEY]["ids"]
    outsider = @lesson.quiz_questions.where.not(id: ids).first
    skip "no spare question" unless outsider
    assert_no_difference -> { ReviewLog.count } do
      post answer_review_path, params: { question_id: outsider.id, choice: outsider.answer }
    end
    assert_redirected_to review_path
  end

  test "a word answered elsewhere since the round began is skipped" do
    sign_in_as(@user)
    get review_path
    id = session[ReviewsController::ROUND_KEY]["ids"].first
    QuizReview.create!(user: @user, quiz_question_id: id, box: 2, fsrs_state: 2, stability: 1.0,
                       difficulty: 5.0, last_reviewed_at: Time.current, due_at: 1.day.from_now)
    get review_path
    assert_equal 1, session[ReviewsController::ROUND_KEY]["pos"]
  end

  def due_review(question, times_correct:)
    QuizReview.create!(user: @user, quiz_question: question, box: 2, fsrs_state: 2, stability: 1.0,
                       difficulty: 5.0, times_correct: times_correct, last_reviewed_at: 2.days.ago, due_at: 1.hour.ago)
  end

  test "a new word is multiple choice" do
    sign_in_as(@user)
    get review_path
    assert_select "button[name=choice]"
    assert_select "button[name=rating]", false
  end

  test "a word answered right before becomes a Say it card, in English to Irish" do
    sign_in_as(@user)
    question = @lesson.quiz_questions.find_by(direction: "en_ga")
    due_review(question, times_correct: 1)
    QuizReview.where(user: @user).where.not(quiz_question: question).delete_all

    get review_path
    assert_response :success
    assert session[ReviewsController::ROUND_KEY]["ids"].first == question.id
    assert_select "button[name=choice]", false
    assert_select "button[name=rating]", 4
    assert_select "[data-controller=reveal]"
  end

  test "Say it with Mayo audio hides the Irish until shown" do
    sign_in_as(@user)
    question = @lesson.quiz_questions.find_by(direction: "ga_en")
    question.source.update!(audio_url: "https://example.com/a.mp3")
    due_review(question, times_correct: 2)
    get review_path
    assert session[ReviewsController::ROUND_KEY]["ids"].first == question.id
    assert_select "[data-testid=say-it-audio] audio[src='https://example.com/a.mp3']"
    assert_select "p[hidden]", text: question.prompt
  end

  test "multiple choice Irish prompts have the Mayo audio" do
    sign_in_as(@user)
    question = @lesson.quiz_questions.find_by(direction: "ga_en")
    question.source.update!(audio_url: "https://example.com/a.mp3")
    QuizReview.where(user: @user).delete_all
    due_review(question, times_correct: 0)
    get review_path
    assert session[ReviewsController::ROUND_KEY]["ids"].first == question.id
    assert_select "audio[src='https://example.com/a.mp3']"
  end

  test "a self-rating schedules the word and Again counts as wrong" do
    sign_in_as(@user)
    question = @lesson.quiz_questions.first
    due_review(question, times_correct: 1)
    QuizReview.where(user: @user).where.not(quiz_question: question).delete_all
    get review_path

    assert_difference -> { ReviewLog.count }, 1 do
      post answer_review_path, params: { question_id: question.id, rating: "again" }
    end
    assert_response :success
    assert_equal 1, QuizReview.find_by(user: @user, quiz_question: question).times_wrong
    assert_select ".line-through", false
  end

  test "Easy is scheduled further out than Good" do
    sign_in_as(@user)
    due = {}
    %w[good easy].each do |rating|
      QuizReview.where(user: @user).delete_all
      session_reset
      question = @lesson.quiz_questions.first
      due_review(question, times_correct: 1)
      get review_path
      id = session[ReviewsController::ROUND_KEY]["ids"].first
      post answer_review_path, params: { question_id: id, rating: rating }
      due[rating] = QuizReview.find_by(user: @user, quiz_question_id: id).due_at
    end
    assert_operator due["easy"], :>, due["good"]
  end

  test "a rating is ignored for a word that is still multiple choice" do
    sign_in_as(@user)
    get review_path
    id = session[ReviewsController::ROUND_KEY]["ids"].first
    post answer_review_path, params: { question_id: id, rating: "easy", choice: "wrong" }
    assert_equal 1, QuizReview.find_by(user: @user, quiz_question_id: id).times_wrong
  end

  test "Hard counts as remembered" do
    sign_in_as(@user)
    question = @lesson.quiz_questions.first
    due_review(question, times_correct: 1)
    QuizReview.where(user: @user).where.not(quiz_question: question).delete_all
    get review_path
    post answer_review_path, params: { question_id: session[ReviewsController::ROUND_KEY]["ids"].first, rating: "hard" }
    assert_response :success
    assert_equal 2, QuizReview.find_by(user: @user, quiz_question: question).times_correct
  end

  private

  def session_reset
    delete reset_review_path
  end
end
