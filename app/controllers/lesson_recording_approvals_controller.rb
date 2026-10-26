# Approves, in one go, the best checked suggestion for each of a lesson's words.
class LessonRecordingApprovalsController < ApplicationController
  before_action :require_admin

  def create
    lesson = Lesson.find_by!(number: params[:lesson_id])
    approved = RecordingSuggestion.approve_checked!(lesson.words_open_to_abairt_recordings, by: current_user)

    redirect_to lesson_recording_suggestions_path(lesson), notice: t(".approved", count: approved)
  end
end
