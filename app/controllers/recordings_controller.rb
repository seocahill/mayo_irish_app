# A whole Abairt recording to listen through, with its transcript following
# along. Only the recordings behind the course's listening clips are offered.
class RecordingsController < ApplicationController
  # Starting a little before a clip's phrase gives the ear a run-in.
  LEAD_IN = 5

  def show
    raise ActiveRecord::RecordNotFound unless ListeningClip.recording_offered?(params[:id], to: current_user)

    @start = (params[:t].to_f - LEAD_IN).clamp(0..)
    @recording = AbairtRecording.find(params[:id])
  rescue AbairtClient::Error
    @error = t(".unavailable")
  end
end
