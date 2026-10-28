require "test_helper"

class LearnersControllerTest < ActionDispatch::IntegrationTest
  test "admins see who is waiting for approval and what learners have done" do
    sign_in_as(users(:admin))

    get learners_path

    assert_response :success
    assert_select "#pending-heading + ul", text: /one@example.com/
    assert_select "form[action=?]", learner_approval_path(users(:one))
    assert_select "a[href=?]", learner_path(users(:two)), text: /two@example.com/
  end

  test "an admin approves someone who signed up" do
    sign_in_as(users(:admin))

    post learner_approval_path(users(:one))

    assert_redirected_to learners_path
    assert users(:one).reload.approved?
  end

  test "a learner's page shows their weeks and the lessons they've started" do
    QuizQuestion.sync_for(lessons(:one))
    QuizReview.create!(user: users(:two), quiz_question: QuizQuestion.first, box: 2, due_at: 1.day.from_now)
    sign_in_as(users(:admin))

    get learner_path(users(:two))

    assert_response :success
    assert_select "h1", text: "two@example.com"
    assert_select "#weeks-heading + div tbody tr", 8
    assert_select "a[href=?]", lesson_path(lessons(:one))
  end

  test "learners can't see the page or approve anyone" do
    sign_in_as(users(:two))

    get learners_path
    assert_redirected_to root_path

    get learner_path(users(:admin))
    assert_redirected_to root_path

    post learner_approval_path(users(:one))
    assert_redirected_to root_path
    assert_not users(:one).reload.approved?
  end

  test "admins find the page from the lessons list" do
    sign_in_as(users(:admin))

    get lessons_path

    assert_select "a[href=?]", learners_path
  end
end
