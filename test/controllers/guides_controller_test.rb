require "test_helper"

class GuidesControllerTest < ActionDispatch::IntegrationTest
  test "learners get the guide, without the editors' part" do
    sign_in_as(users(:two))

    get guide_path

    assert_response :success
    assert_select "h1", text: "How this course works"
    assert_select "#listening"
    assert_select "#editors", count: 0
  end

  test "editors also get their part" do
    sign_in_as(users(:admin))

    get guide_path

    assert_select "#editors h2", text: "For editors"
  end

  test "Today links to it" do
    sign_in_as(users(:two))

    get root_path

    assert_select "a[href=?]", guide_path
  end

  test "it's for signed-in people" do
    get guide_path

    assert_redirected_to new_session_path
  end
end
