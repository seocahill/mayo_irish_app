require "test_helper"

class CourseProposalsControllerTest < ActionDispatch::IntegrationTest
  test "admins see an empty state" do
    sign_in_as(users(:admin))
    get course_proposals_path
    assert_response :success
    assert_select "#no-proposals"
  end

  test "admins see proposals, highest priority first" do
    CourseProposal.create!(kind: "gap", title: "Low one", priority: 0)
    CourseProposal.create!(kind: "new_lesson", title: "Weather lesson", rationale: "No weather words", priority: 5)
    sign_in_as(users(:admin))
    get course_proposals_path
    assert_select "#proposals li", 2
    assert_select "#proposals li:first-child", /Weather lesson/
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))
    get course_proposals_path
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get course_proposals_path
    assert_response :redirect
  end
end
