# First-run questions: where the learner is from, and where they are starting.
# Also used to change those answers later.
class OnboardingsController < ApplicationController
  def new
    @user = current_user
  end

  def create
    @user = current_user
    if @user.complete_onboarding(onboarding_params)
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def onboarding_params
    params.require(:user).permit(:place, :dialect_region, :door)
  end
end
