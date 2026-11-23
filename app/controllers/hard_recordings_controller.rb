# Admin-only: the whole recordings learners most often couldn't follow yet.
class HardRecordingsController < ApplicationController
  before_action :require_admin

  def show
    @rows = HardRecordings.new.rows
  end
end
