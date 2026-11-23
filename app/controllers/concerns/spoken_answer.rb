# A learner's turn said aloud instead of typed: the recording goes through
# ABAIR's recogniser and comes back as text, with how long they spoke (as the
# page measured it) for their minutes spoken. Used by the comhrá and the tutor chat.
module SpokenAnswer
  extend ActiveSupport::Concern

  class RecordingTooLong < StandardError; end
  class NothingHeard < StandardError; end

  private

  def transcribe(audio)
    return if audio.blank?
    raise RecordingTooLong if audio.size > AbairClient::MAX_AUDIO_BYTES

    heard = AbairClient.new.recognise(audio.read, filename: audio.original_filename.presence || "speech.webm").squish
    heard.presence || raise(NothingHeard)
  end

  # How long the learner spoke, for a recorded turn only.
  def spoken_seconds
    params[:spoken_seconds].to_i.clamp(ChatMessage::SPOKEN_SECONDS) if params[:message].blank? && params[:audio].present?
  end
end
