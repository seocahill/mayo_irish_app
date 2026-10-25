# The comhrá for a lesson. What the learner says goes to
# LessonConversationMessagesController; this shows the conversation and starts
# a new one.
class LessonConversationsController < ApplicationController
  include LessonConversationScoped

  def show
    @messages = @chat_session.chat_messages.to_a
    @speech = AbairClient.configured?
  end

  # Starting again leaves the old conversation in place, so replies a learner
  # flagged are still there for an editor.
  def destroy
    current_user.chat_sessions.conversation.create!(lesson: @lesson)
    redirect_to lesson_conversation_path(@lesson)
  end
end
