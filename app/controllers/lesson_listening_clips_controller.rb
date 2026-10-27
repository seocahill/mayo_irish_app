# Where an editor sees the listening clips found for a lesson's words. Each
# word's clips load in their own frame (VocabularyItemListeningClipsController),
# so the slow part, searching Abairt and checking each clip, happens a word at a time.
class LessonListeningClipsController < ApplicationController
  before_action :require_admin

  def index
    @lesson = Lesson.find_by!(number: params[:lesson_id])
    @words = @lesson.vocabulary_items.ordered
  end
end
