# What a learner has listened to: the conversations, and the clips with
# whether they made them out, to go back to. Saying whether they made out a
# clip also sets it aside so the next one comes up.
class ListensController < ApplicationController
  SHOWN = 100

  def index
    @listening_times = current_user.listening_times.order(updated_at: :desc).to_a
    @recording_titles = ListeningClip.where(abairt_recording_id: @listening_times.map(&:abairt_recording_id))
                                     .distinct.pluck(:abairt_recording_id, :abairt_recording_title).to_h
    @listens = current_user.listens.joins(:listening_clip).merge(ListeningClip.visible_to(current_user))
                           .includes(listening_clip: :vocabulary_item).order(updated_at: :desc).limit(SHOWN)
  end

  def create
    clip = ListeningClip.visible_to(current_user).find(params[:listening_clip_id])
    current_user.listens.find_or_initialize_by(listening_clip: clip)
                .update!(understood: ActiveModel::Type::Boolean.new.cast(params.expect(:understood)))

    redirect_to root_path, notice: t(".saved")
  end
end
