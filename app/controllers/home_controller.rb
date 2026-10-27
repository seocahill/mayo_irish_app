class HomeController < ApplicationController
  allow_unauthenticated_access
  before_action :require_onboarding, if: :authenticated?

  def show
    return render :welcome unless authenticated?

    @daily_path = DailyPath.new(current_user)
    @spoken_time = SpokenTime.new(current_user)
    @listening_minutes = ListeningTime.minutes_for(current_user)
  end

  private

  def require_onboarding
    redirect_to new_onboarding_path unless current_user.onboarded?
  end
end
