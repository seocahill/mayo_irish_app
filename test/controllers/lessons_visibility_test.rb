require "test_helper"

class LessonsVisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @learner = users(:two) # approved, non-admin
    @draft = Lesson.create!(number: 9200, title: "Draft Lesson", position: 9200, published: false)
  end

  test "learners do not see draft lessons on the index" do
    sign_in_as(@learner)
    get lessons_path
    assert_response :success
    assert_no_match "Draft Lesson", @response.body
  end

  test "admins do see draft lessons on the index" do
    sign_in_as(@admin)
    get lessons_path
    assert_response :success
    assert_match "Draft Lesson", @response.body
  end

  test "opening a lesson is recorded, so Today can move on from it" do
    sign_in_as(@learner)

    assert_difference -> { @learner.lesson_visits.count } do
      get lesson_path(lessons(:one))
    end
  end

  test "learners are redirected away from a draft lesson page" do
    sign_in_as(@learner)
    get lesson_path(@draft)
    assert_redirected_to root_path
  end

  test "admins can view a draft lesson page" do
    sign_in_as(@admin)
    get lesson_path(@draft)
    assert_response :success
  end

  test "admins can publish a draft via update" do
    sign_in_as(@admin)
    patch lesson_path(@draft), params: { lesson: { published: true } }
    assert @draft.reload.published?
  end

  test "index shows how many words are due for review in each lesson" do
    sign_in_as(@learner)
    lesson = lessons(:one)
    item = lesson.vocabulary_items.first || lesson.vocabulary_items.create!(irish: "bó", english: "cow")
    QuizQuestion.sync_for(lesson)
    question = QuizQuestion.where(lesson: lesson).first
    QuizReview.create!(user: @learner, quiz_question: question, due_at: 1.hour.ago)

    get lessons_path
    assert_response :success
    assert_match "1 to review", @response.body
  end

  test "index shows no due note when nothing is due" do
    sign_in_as(@learner)
    get lessons_path
    assert_no_match "to review", @response.body
  end
end
