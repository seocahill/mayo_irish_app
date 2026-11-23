# A learner saying whether they followed a whole recording: their own word, not
# a test, kept with their listening time for it. Only once they have listened:
# a listening time is what the page reports while the recording plays.
class RecordingFollowsController < ApplicationController
  def update
    raise ActiveRecord::RecordNotFound unless ListeningClip.recording_offered?(params[:recording_id], to: current_user)

    followed = ActiveModel::Type::Boolean.new.cast(params.expect(:followed))
    time = current_user.listening_times.find_by(abairt_recording_id: params[:recording_id].to_i)
    return redirect_to recording_path(params[:recording_id], anchor: "followed"), alert: t(".listen_first") if time.nil?

    # update_columns leaves updated_at alone: it stands for when they last listened (Your listening, usage, Today).
    time.update_columns(followed: followed)
    notice = followed ? t(".followed") : t(".not_yet")
    redirect_to recording_path(params[:recording_id], anchor: "followed"), notice: notice
  end
end
