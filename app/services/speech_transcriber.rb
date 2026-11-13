# Turns a recording of a learner's English into text with OpenAI. Irish speech
# goes to ABAIR's recogniser instead (see AbairClient).
#
#   SpeechTranscriber.new.transcribe(audio_bytes, filename: "speech.webm")  # => "how do I count people"
class SpeechTranscriber
  class Error < StandardError; end

  MODEL = "gpt-4o-transcribe".freeze
  MAX_AUDIO_BYTES = 10.megabytes

  def initialize(client: OpenaiClient.build(request_timeout: 60))
    @client = client
  end

  # OpenAI tells the audio format from the file name, so the bytes go through
  # a temporary file that keeps the recording's extension.
  def transcribe(audio, filename: "speech.webm")
    Tempfile.create([ "speech", File.extname(filename).presence || ".webm" ], binmode: true) do |file|
      file.write(audio)
      file.rewind
      response = @client.audio.transcribe(parameters: { model: MODEL, file: file, language: "en" })
      response.fetch("text").to_s.squish
    end
  rescue Faraday::Error, KeyError => e
    raise Error, "The recording could not be transcribed: #{e.message}"
  end
end
