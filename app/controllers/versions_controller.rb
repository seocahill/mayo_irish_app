# A lesson's edit history, for admins: who changed what, with an undo link.
class VersionsController < ApplicationController
  before_action :require_admin

  def index
    @lesson = Lesson.find_by!(number: params[:lesson_id])
    @entries = LessonHistory.new(@lesson).entries
  end
end
