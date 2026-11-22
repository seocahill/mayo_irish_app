# The record-yourself button reporting how long the learner just recorded
# themselves (only the length; the audio stays in the browser).
class SpeakingTimesController < ApplicationController
  # A real learner records a few times a minute; this only stops a runaway script.
  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }, with: -> { head :too_many_requests }

  def create
    SpeakingDay.add(current_user, params[:seconds])
    head :no_content
  end
end
