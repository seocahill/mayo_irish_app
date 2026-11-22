# "Type what you hear" on a listening clip: lines up what the learner typed
# against the clip's transcript. Nothing is stored; the learner still says how
# it went with I got it / Not yet.
class DictationsController < ApplicationController
  def create
    @clip = ListeningClip.visible_to(current_user).find(params[:listening_clip_id])
    @dictation = Dictation.new(@clip.irish, params[:heard])
  end
end
