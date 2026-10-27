# A Mayo speaker's phrase for a learner to listen to and work out. Editors can
# hide a clip from learners, or list it again.
class ListeningClipsController < ApplicationController
  before_action :require_admin, only: :update

  def show
    @clip = ListeningClip.visible_to(current_user).includes(:vocabulary_item).find(params[:id])
  end

  def update
    clip = ListeningClip.find(params[:id])
    case params[:status]
    when "hidden" then clip.hide!(by: current_user)
    when "listed" then clip.list!(by: current_user)
    else return head :unprocessable_content
    end

    redirect_to turbo_frame_request? ? vocabulary_item_listening_clips_path(clip.vocabulary_item) : listening_clip_path(clip)
  end
end
