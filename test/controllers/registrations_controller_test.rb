require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "without an invitation there's no form, only a note that it's invite only" do
    [ new_registration_path, new_registration_path(invitation: "made-up") ].each do |path|
      get path

      assert_response :not_found
      assert_select "h1", "Invite only"
      assert_select "form[action=?]", registration_path, count: 0
    end
  end

  test "used and expired invitations don't open the form" do
    %i[accepted expired].each do |name|
      get new_registration_path(invitation: invitations(name).token)

      assert_response :not_found
      assert_select "form[action=?]", registration_path, count: 0
    end
  end

  test "can't register by posting without an invitation" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: registration }
    end
    assert_response :not_found
  end

  test "an invitation lets one person in, signed in and approved" do
    invitation = invitations(:open)
    get new_registration_path(invitation: invitation.token)
    assert_select "input[type=hidden][name=invitation][value=?]", invitation.token

    assert_difference -> { User.count }, 1 do
      post registration_path, params: { invitation: invitation.token, user: registration }
    end

    user = User.find_by!(email_address: "invited@example.com")
    assert user.approved?
    assert_equal user, invitation.reload.user
    assert_redirected_to root_path
    follow_redirect!
    assert_redirected_to new_onboarding_path
  end

  test "an invitation only works once" do
    invitation = invitations(:open)
    post registration_path, params: { invitation: invitation.token, user: registration }
    sign_out

    assert_no_difference -> { User.count } do
      post registration_path, params: { invitation: invitation.token, user: registration(email_address: "second@example.com") }
    end
    assert_response :not_found
  end

  test "a failed registration keeps the invitation open" do
    invitation = invitations(:open)

    post registration_path, params: { invitation: invitation.token, user: registration(password_confirmation: "nope") }

    assert_response :unprocessable_entity
    assert_nil invitation.reload.accepted_at
    assert_select "input[type=hidden][name=invitation][value=?]", invitation.token
  end

  private

  def registration(**overrides)
    { email_address: "invited@example.com", password: "a long password", password_confirmation: "a long password" }.merge(overrides)
  end
end
