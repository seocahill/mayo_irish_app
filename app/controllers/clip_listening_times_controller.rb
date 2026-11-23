# A listening clip's page reporting, every half minute or so and when the
# learner pauses or leaves, how long the clip has been playing. Counts towards
# minutes listened, like whole recordings do.
class ClipListeningTimesController < ApplicationController
  # The page reports a few times a minute at most; this only stops a runaway script.
  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }, with: -> { head :too_many_requests }

  def update
    ListeningClip.visible_to(current_user).find(params[:listening_clip_id])
    ListeningDay.add_clip(current_user, params[:seconds])
    head :no_content
  end
end
