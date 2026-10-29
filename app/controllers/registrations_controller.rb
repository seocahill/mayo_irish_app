# Registering is by invitation only: without an open invitation link there's
# no form, only a note on how to get one.
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create pending]
  skip_before_action :require_approval, only: %i[pending]
  before_action :redirect_if_authenticated, only: :new
  before_action :set_invitation, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @invitation.accept(@user)
      start_new_session_for @user
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def pending
    # shown to anyone signed up before invitations, while awaiting admin approval
  end

  private

  def set_invitation
    @invitation = Invitation.open.find_by(token: params[:invitation].to_s)
    render :invite_only, status: :not_found unless @invitation
  end

  def registration_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end
