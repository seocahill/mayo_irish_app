class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create pending]
  skip_before_action :require_approval, only: %i[pending]
  before_action :redirect_if_authenticated, only: :new

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      redirect_to pending_approval_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def pending
    # shown after signup while awaiting admin approval
  end

  private

  def registration_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end
