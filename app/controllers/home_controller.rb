class HomeController < ApplicationController
  allow_unauthenticated_access
  before_action :require_onboarding, if: :authenticated?

  def show
    return render :welcome unless authenticated?

    @whats_new = current_user.whats_new_unseen
    @daily_path = DailyPath.new(current_user)
    @minutes = params[:minutes].to_i.presence_in(DailyPath::TIME_CHOICES)
    @forecast = QuizReview.forecast_for(current_user)
    @spoken_time = SpokenTime.new(current_user)
    @listening_minutes = ListeningTime.minutes_for(current_user)
    @course_words = @daily_path.course_words
    @milestones = Milestones.new(current_user, known_words: @daily_path.known_words, listening_minutes: @listening_minutes)
  end

  private

  def require_onboarding
    redirect_to new_onboarding_path unless current_user.onboarded?
  end
end
