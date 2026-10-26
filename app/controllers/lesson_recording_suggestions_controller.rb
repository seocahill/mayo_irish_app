# Where an editor reviews real Mayo recordings from Abairt for a lesson's words.
# Each word's suggestions load in their own frame (VocabularyItemRecordingSuggestionsController),
# so the slow part, searching Abairt and checking each clip, happens a word at a time.
class LessonRecordingSuggestionsController < ApplicationController
  before_action :require_admin

  def index
    @lesson = Lesson.find_by!(number: params[:lesson_id])
    @words = @lesson.words_open_to_abairt_recordings
    @checked_count = RecordingSuggestion.pending.where(check_passed: true, vocabulary_item: @words).distinct.count(:vocabulary_item_id)
  end
end
