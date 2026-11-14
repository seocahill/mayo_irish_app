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
end
