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

  test "admins capture an idea, kept verbatim" do
    sign_in_as(users(:admin))
    text = "A lesson on the weather,\nespecially the wind in Erris."
    assert_difference -> { CourseProposal.count }, 1 do
      post course_proposals_path, params: { raw_text: text }
    end
    assert_redirected_to course_proposals_path
    idea = CourseProposal.last
    assert_equal text, idea.raw_text
    assert_equal "idea", idea.kind
    assert_equal "captured", idea.status
  end

  test "a blank idea is not saved" do
    sign_in_as(users(:admin))
    assert_no_difference -> { CourseProposal.count } do
      post course_proposals_path, params: { raw_text: "   " }
    end
    assert_redirected_to course_proposals_path
  end

  test "learners cannot capture ideas" do
    sign_in_as(users(:two))
    assert_no_difference -> { CourseProposal.count } do
      post course_proposals_path, params: { raw_text: "hello" }
    end
  end

  test "an over-long idea is rejected" do
    sign_in_as(users(:admin))
    assert_no_difference -> { CourseProposal.count } do
      post course_proposals_path, params: { raw_text: "a" * 2001 }
    end
    assert_equal I18n.t("course_proposals.create.too_long"), flash[:alert]
  end

  test "the idea box and a saved idea's words show on the list" do
    sign_in_as(users(:admin))
    post course_proposals_path, params: { raw_text: "Weather.\nWind in Erris." }
    follow_redirect!
    assert_select "form textarea[name=raw_text]"
    assert_select "#proposals li", /Wind in Erris/
  end
end
