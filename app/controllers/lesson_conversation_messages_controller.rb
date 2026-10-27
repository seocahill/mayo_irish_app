# One turn of the comhrá. The learner types or records what they say; speech
# goes through ABAIR's recogniser and the reply comes from LessonConversation.
# The page then reads the reply aloud in ABAIR's voice.
class LessonConversationMessagesController < ApplicationController
  include LessonConversationScoped

  class RecordingTooLong < StandardError; end
  class NothingHeard < StandardError; end

  rate_limit to: 10, within: 1.minute, by: -> { current_user.id }, name: "minute",
             with: -> { back_with t("lesson_conversation_messages.create.too_fast") }
  rate_limit to: 150, within: 1.day, by: -> { current_user.id }, name: "day",
             with: -> { back_with t("lesson_conversation_messages.create.daily_limit") }

  # A blank message is only accepted to open an empty conversation.
  def create
    text = params[:message].presence || transcribe(params[:audio])
    return back_with(nil) if text.blank? && @chat_session.chat_messages.any?

    flash[:play] = LessonConversation.new(@chat_session).reply_to(text, spoken_seconds: spoken_seconds).id
    back_with(nil)
  rescue LessonConversation::Error
    back_with t(".no_reply")
  rescue RecordingTooLong
    back_with t(".too_long")
  rescue NothingHeard
    back_with t(".not_heard")
  rescue AbairClient::Error
    back_with t(".no_speech_service")
  end

  private

  def transcribe(audio)
    return if audio.blank?
    raise RecordingTooLong if audio.size > AbairClient::MAX_AUDIO_BYTES

    heard = AbairClient.new.recognise(audio.read, filename: audio.original_filename.presence || "speech.webm").squish
    heard.presence || raise(NothingHeard)
  end

  # How long the learner spoke, as the page measured it, for a recorded turn.
  def spoken_seconds
    params[:spoken_seconds].to_i.clamp(ChatMessage::SPOKEN_SECONDS) if params[:message].blank? && params[:audio].present?
  end

  def back_with(alert)
    redirect_to lesson_conversation_path(params[:lesson_id]), alert: alert
  end
end
