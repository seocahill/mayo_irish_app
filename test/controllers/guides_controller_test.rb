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

  test "anyone can read it before signing in, and is told how to join" do
    get guide_path

    assert_response :success
    assert_select "#listening"
    assert_select "#editors", count: 0
    assert_select "#joining", text: /invitation link/
    assert_select "#joining a[href=?]", new_session_path
  end

  test "people waiting to be let in can read it" do
    sign_in_as(users(:one))

    get guide_path

    assert_response :success
  end

  test "the guide links to the 1926 Gaeltacht map" do
    get guide_path

    assert_select "#approach a[href=?]", OnboardingsHelper::GAELTACHT_1926_URL
  end

  test "the sign-in and register pages send people already signed in to Today" do
    sign_in_as(users(:admin))

    [ new_session_path, new_registration_path(invitation: invitations(:open).token) ].each do |path|
      get path

      assert_redirected_to root_path
    end
  end

  test "the sign-in and register pages sum it up and say it's invite only" do
    [ new_session_path, new_registration_path(invitation: invitations(:open).token) ].each do |path|
      get path

      assert_select "section h2", text: "A course in the Irish of Mayo"
      assert_select "p", text: /invite only/
      assert_select "a[href=?]", guide_path
    end
  end
end
