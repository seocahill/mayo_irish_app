# Synthetic speech for a piece of Irish text. Audio is cached by text and
# voice, since the same words are asked for again and again.
class Pronunciation
  MAX_CHARACTERS = 400
  CACHE_FOR = 30.days

  def initialize(text, client: AbairClient.new)
    @text = text.to_s.squish.first(MAX_CHARACTERS)
    @client = client
  end

  # WAV bytes.
  def audio
    Rails.cache.fetch([ "pronunciation", Digest::SHA256.hexdigest("#{voice}|#{@text}") ], expires_in: CACHE_FOR) do
      @client.synthesise(@text)
    end
  end

  private

  def voice = AbairClient.voice
end
