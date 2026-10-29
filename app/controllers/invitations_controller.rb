# An admin making a sign-up link to copy and send to someone, or taking one back.
class InvitationsController < ApplicationController
  before_action :require_admin

  def create
    current_user.invitations.create!
    redirect_to learners_path(anchor: "invitations-heading"), notice: t(".created")
  end

  def destroy
    Invitation.open.find(params[:id]).destroy!
    redirect_to learners_path(anchor: "invitations-heading"), notice: t(".revoked")
  end
end
