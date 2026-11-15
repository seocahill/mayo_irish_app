# First-run questions: where the learner is from, and where they are starting.
# Also used to change those answers later.
class OnboardingsController < ApplicationController
  def new
    @user = current_user
  end

  def create
    @user = current_user
    first_time = !@user.onboarded?
    if @user.complete_onboarding(onboarding_params)
      first_lesson = DailyPath.new(@user).first_lesson_path
      if first_time && first_lesson && @user.lesson_visits.none?
        redirect_to first_lesson, notice: t(".start_here")
      else
        redirect_to root_path
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def onboarding_params
    params.require(:user).permit(:place, :dialect_region, :door)
  end
end
