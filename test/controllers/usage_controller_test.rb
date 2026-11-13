require "test_helper"

class UsageControllerTest < ActionDispatch::IntegrationTest
  test "admins see the weekly figures" do
    sign_in_as(users(:admin))

    get usage_path

    assert_response :success
    assert_select "#weeks-heading"
    assert_select "#weeks-heading + ul > li", UsageReport::WEEKS
    assert_select "#stop-heading"
  end

  test "learners cannot see it" do
    sign_in_as(users(:two))

    get usage_path

    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get usage_path

    assert_redirected_to new_session_path
  end
end
