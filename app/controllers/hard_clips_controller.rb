# Admin-only: the listening clips learners most often couldn't make out.
class HardClipsController < ApplicationController
  before_action :require_admin

  def show
    @rows = HardClips.new.rows
  end
end
