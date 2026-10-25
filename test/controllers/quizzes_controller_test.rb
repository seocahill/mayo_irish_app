require "test_helper"

class QuizzesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
  end

  test "unauthenticated user is redirected to login" do
    get lesson_quiz_path(@lesson)
    assert_redirected_to new_session_path
  end

  test "show generates questions and starts a round" do
    sign_in_as(@user)
    get lesson_quiz_path(@lesson)
    assert_response :success
    assert_operator @lesson.quiz_questions.count, :>, 0
    assert_match(/name="question_id"/, response.body)
  end

  test "a correct answer records a known review" do
    sign_in_as(@user)
    get lesson_quiz_path(@lesson)
    question = current_question

    assert_difference -> { QuizReview.count }, 1 do
      post answer_lesson_quiz_path(@lesson), params: { question_id: question.id, choice: question.answer }
    end
    assert_response :success

    review = QuizReview.find_by(user: @user, quiz_question: question)
    assert review.known?
    assert_equal 1, review.times_correct
  end

  test "a wrong answer demotes to box 1" do
    sign_in_as(@user)
    get lesson_quiz_path(@lesson)
    question = current_question
    wrong = question.distractors.first

    post answer_lesson_quiz_path(@lesson), params: { question_id: question.id, choice: wrong }
    review = QuizReview.find_by(user: @user, quiz_question: question)
    assert_equal 1, review.box
    assert_not review.known?
  end

  test "finishing the last question renders the summary" do
    sign_in_as(@user)
    # One-question lesson by leaving a single unanswered question due.
    QuizQuestion.sync_for(@lesson)
    @lesson.quiz_questions.offset(1).find_each do |q|
      QuizReview.create!(user: @user, quiz_question: q, box: 5, due_at: 1.year.from_now)
    end

    get lesson_quiz_path(@lesson)
    question = current_question
    post answer_lesson_quiz_path(@lesson), params: { question_id: question.id, choice: question.answer }
    follow_redirect! if response.redirect?
    get lesson_quiz_path(@lesson) # round exhausted -> summary
    assert_match(/Round complete/, response.body)
  end

  test "all-known lesson with nothing due renders the caught-up state" do
    sign_in_as(@user)
    QuizQuestion.sync_for(@lesson)
    @lesson.quiz_questions.find_each do |q|
      QuizReview.create!(user: @user, quiz_question: q, box: 5, due_at: 1.year.from_now)
    end

    get lesson_quiz_path(@lesson)
    assert_response :success
    assert_match(/Nothing left to review right now/, response.body)
  end

  test "reset clears the round and returns to the lesson" do
    sign_in_as(@user)
    get lesson_quiz_path(@lesson)
    delete reset_lesson_quiz_path(@lesson)
    assert_redirected_to lesson_path(@lesson)
  end

  private

  # Pulls the current question id out of the rendered quiz form.
  def current_question
    input = response.body[/<input[^>]*name="question_id"[^>]*>/]
    id = input && input[/value="(\d+)"/, 1]
    assert id, "expected a question id in the response"
    QuizQuestion.find(id)
  end
end
