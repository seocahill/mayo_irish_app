# The comhrá for a lesson. The learner types or records what they say; speech
# goes through ABAIR's recogniser, the reply comes from LessonConversation, and
# the page reads it aloud in ABAIR's voice.
class LessonConversationsController < ApplicationController
  class RecordingTooLong < StandardError; end
  class NothingHeard < StandardError; end

  rate_limit to: 10, within: 1.minute, by: -> { current_user.id }, only: :message, name: "minute",
             with: -> { back_with t("lesson_conversations.message.too_fast") }
  rate_limit to: 150, within: 1.day, by: -> { current_user.id }, only: :message, name: "day",
             with: -> { back_with t("lesson_conversations.message.daily_limit") }

  before_action :set_lesson
  before_action :set_chat_session

  def show
    @messages = @chat_session.chat_messages.to_a
    @speech = AbairClient.configured?
  end

  # A blank message is only accepted to open an empty conversation.
  def message
    text = params[:message].presence || transcribe(params[:audio])
    return back_with(nil) if text.blank? && @chat_session.chat_messages.any?

    reply = LessonConversation.new(@chat_session).reply_to(text)
    flash[:play] = reply.id
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

  # Starting again leaves the old conversation in place, so replies a learner
  # flagged are still there for an editor.
  def destroy
    current_user.chat_sessions.conversation.create!(lesson: @lesson)
    back_with(nil)
  end

  private

  def set_lesson
    @lesson = Lesson.visible_to(current_user).find_by!(number: params[:lesson_id])
  end

  def set_chat_session
    sessions = current_user.chat_sessions.conversation.where(lesson: @lesson)
    @chat_session = sessions.order(:id).last || sessions.build
  end

  def transcribe(audio)
    return if audio.blank?
    raise RecordingTooLong if audio.size > AbairClient::MAX_AUDIO_BYTES

    heard = AbairClient.new.recognise(audio.read, filename: audio.original_filename.presence || "speech.webm").squish
    heard.presence || raise(NothingHeard)
  end

  def back_with(alert)
    redirect_to lesson_conversation_path(params[:lesson_id]), alert: alert
  end
end
