# A learner flags a comhrá reply whose Irish looks wrong, for an editor to check.
class ChatMessageFlagsController < ApplicationController
  def create
    message = ChatMessage.where(role: "assistant").joins(:chat_session)
                         .merge(current_user.chat_sessions.conversation).find(params[:chat_message_id])
    message.flag!

    redirect_to lesson_conversation_path(message.chat_session.lesson), notice: t(".flagged")
  end
end
