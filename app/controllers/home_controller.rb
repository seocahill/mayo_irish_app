class HomeController < ApplicationController
  before_action :require_onboarding

  def show
    @daily_path = DailyPath.new(current_user)
  end

  private

  def require_onboarding
    redirect_to new_onboarding_path unless current_user.onboarded?
  end
end
