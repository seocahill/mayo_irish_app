require "test_helper"

class BottomNavTest < ActionDispatch::IntegrationTest
  test "signed-in learners get the four-tab bottom bar with the current page marked" do
    sign_in_as(users(:two))

    get lessons_path

    assert_select "nav[aria-label='Main'] a", 4
    assert_select "nav[aria-label='Main'] a[href='#{lessons_path}'][aria-current='page']", 1
    assert_select "nav[aria-label='Main'] a[href='#{new_course_question_path}']", 1
    assert_select "nav[aria-label='Main'] a[href='#{search_path}']", 1
    assert_select "nav[aria-label='Main'] a[aria-current='page']", 1
  end

  test "Today is the current tab at the root" do
    sign_in_as(users(:two))

    get root_path

    assert_select "nav[aria-label='Main'] a[href='#{root_path}'][aria-current='page']", 1
  end

  test "signed-out visitors get no bottom bar" do
    get new_session_path

    assert_select "nav[aria-label='Main']", 0
  end
end
