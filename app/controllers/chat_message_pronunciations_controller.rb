# A comhrá reply read aloud by ABAIR's synthetic voice.
class ChatMessagePronunciationsController < ApplicationController
  rate_limit to: 60, within: 1.minute, by: -> { current_user.id }

  def show
    message = ChatMessage.conversation_replies_to(current_user).find(params[:chat_message_id])

    expires_in 1.week
    send_data Pronunciation.new(message.content).audio, type: "audio/wav", disposition: :inline
  rescue AbairClient::Error
    head :bad_gateway
  end
end
