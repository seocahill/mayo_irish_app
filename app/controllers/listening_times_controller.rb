# The recording page reporting, every half minute or so, how long the learner
# has been listening.
class ListeningTimesController < ApplicationController
  def update
    return head :not_found unless ListeningClip.recording_offered?(params[:recording_id], to: current_user)

    current_user.listening_times.find_or_create_by!(abairt_recording_id: params[:recording_id]).add(params[:seconds])
    head :no_content
  end
end
