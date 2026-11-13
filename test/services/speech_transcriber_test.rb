require "test_helper"

class SpeechTranscriberTest < ActiveSupport::TestCase
  test "returns what OpenAI heard, tidied" do
    stub = stub_openai_transcription("  how do I   count people ")

    assert_equal "how do I count people", SpeechTranscriber.new.transcribe("audio-bytes", filename: "speech.ogg")
    assert_requested stub
  end

  test "sends the recording as a file with its extension, asking for English" do
    stub = stub_openai_transcription.with { |request|
      request.body.include?('filename="speech') && request.body.include?(".mp4") && request.body.include?("en") &&
        request.body.include?(SpeechTranscriber::MODEL)
    }

    SpeechTranscriber.new.transcribe("audio-bytes", filename: "recording.mp4")
    assert_requested stub
  end

  test "fails with an Error when OpenAI can't be used" do
    stub_openai_transcription(status: 500)

    assert_raises(SpeechTranscriber::Error) { SpeechTranscriber.new.transcribe("audio-bytes") }
  end
end
