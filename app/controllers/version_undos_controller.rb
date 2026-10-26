# Undoes a single recorded change to a lesson (see VersionUndo).
class VersionUndosController < ApplicationController
  before_action :require_admin
  before_action :set_lesson

  def create
    version = PaperTrail::Version.where(lesson_id: @lesson.id).find(params[:version_id])

    VersionUndo.new(version).call
    redirect_to lesson_versions_path(@lesson), notice: t(".undone")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    redirect_to lesson_versions_path(@lesson), alert: t(".failed", reason: e.message)
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:lesson_id])
  end
end
