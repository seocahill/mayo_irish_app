# Finds the lesson (if the user may see it) and the user's current comhrá for
# it, which is the latest one, or a new unsaved one when there is none yet.
module LessonConversationScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_lesson
    before_action :set_chat_session
  end

  private
    def set_lesson
      @lesson = Lesson.visible_to(current_user).find_by!(number: params[:lesson_id])
    end

    def set_chat_session
      sessions = current_user.chat_sessions.conversation.where(lesson: @lesson)
      @chat_session = sessions.order(:id).last || sessions.build
    end
end
