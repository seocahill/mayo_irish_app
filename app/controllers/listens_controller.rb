# A learner saying whether they made out a clip, which also sets it aside so
# the next one comes up.
class ListensController < ApplicationController
  def create
    clip = ListeningClip.visible_to(current_user).find(params[:listening_clip_id])
    current_user.listens.find_or_initialize_by(listening_clip: clip)
                .update!(understood: ActiveModel::Type::Boolean.new.cast(params.expect(:understood)))

    redirect_to root_path, notice: t(".saved")
  end
end
