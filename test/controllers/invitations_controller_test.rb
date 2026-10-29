require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  test "admins make a link to copy from the learners page" do
    sign_in_as(users(:admin))

    assert_difference -> { users(:admin).invitations.count }, 1 do
      post invitations_path
    end
    follow_redirect!

    invitation = Invitation.order(:created_at).last
    assert_select "input[readonly][value=?]", new_registration_url(invitation: invitation.token)
  end

  test "used and expired links aren't listed" do
    sign_in_as(users(:admin))

    get learners_path

    assert_select "input[readonly][value*=?]", invitations(:open).token
    %i[accepted expired].each do |name|
      assert_select "input[readonly][value*=?]", invitations(name).token, count: 0
    end
  end

  test "admins can take a link back" do
    sign_in_as(users(:admin))

    delete invitation_path(invitations(:open))

    assert_not Invitation.exists?(invitations(:open).id)
    assert_redirected_to learners_path(anchor: "invitations-heading")
  end

  test "learners can't make or take back links" do
    sign_in_as(users(:two))

    assert_no_difference -> { Invitation.count } do
      post invitations_path
      delete invitation_path(invitations(:open))
    end
  end
end
