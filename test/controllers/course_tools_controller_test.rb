require "test_helper"

class CourseToolsControllerTest < ActionDispatch::IntegrationTest
  test "admins see a link to every course tool" do
    sign_in_as(users(:admin))

    get course_tools_path

    assert_response :success
    [ vocabulary_gaps_path, where_taught_path, course_proposals_path, dialect_substitutions_path, usage_path, learners_path, flagged_replies_path, hard_words_path ].each do |path|
      assert_select "#course-tools a[href='#{path}']"
    end
  end

  test "the lessons page links admins to the menu" do
    sign_in_as(users(:admin))

    get lessons_path

    assert_select "a[href='#{course_tools_path}']"
  end

  test "learners see no link and cannot open it" do
    sign_in_as(users(:two))

    get lessons_path
    assert_select "a[href='#{course_tools_path}']", false

    get course_tools_path
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get course_tools_path

    assert_response :redirect
  end
end
