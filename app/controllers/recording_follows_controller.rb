# A learner saying whether they followed a whole recording: their own word, not
# a test, kept with their listening time for it.
class RecordingFollowsController < ApplicationController
  def update
    raise ActiveRecord::RecordNotFound unless ListeningClip.recording_offered?(params[:recording_id], to: current_user)

    followed = ActiveModel::Type::Boolean.new.cast(params.expect(:followed))
    # update_columns leaves updated_at alone: it stands for when they last listened (Your listening, usage).
    current_user.listening_times.find_or_create_by!(abairt_recording_id: params[:recording_id]).update_columns(followed: followed)

    notice = followed ? t(".followed") : t(".not_yet")
    redirect_to recording_path(params[:recording_id], anchor: "followed"), notice: notice
  end
end
