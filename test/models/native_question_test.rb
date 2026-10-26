require "test_helper"

class NativeQuestionTest < ActiveSupport::TestCase
  # Stands in for AbairtClient.
  class Abairt
    attr_reader :asked

    def initialize(reply) = (@reply = reply) && (@asked = [])

    def ask(audio, asker_label:)
      raise @reply if @reply.is_a?(Exception)

      @asked << asker_label
      @reply
    end

    def question(_id) = @reply
  end

  setup do
    @learner = users(:two)
    @audio = Rack::Test::UploadedFile.new(StringIO.new("recording"), "audio/webm", original_filename: "question.webm")
  end

  test "sends the recording to Abairt, then records the question" do
    abairt = Abairt.new({ "id" => 7, "status" => "waiting", "audio_url" => "https://abairt.test/q7" })

    question = NativeQuestion.ask!(user: @learner, audio: @audio, lesson: lessons(:one), abairt: abairt)

    assert_equal [ 7, "waiting", "https://abairt.test/q7", lessons(:one) ], question.values_at(:abairt_question_id, :status, :audio_url).push(question.lesson)
    assert_equal [ "two, Mayo Irish course" ], abairt.asked
  end

  test "nothing is saved when Abairt doesn't take it" do
    assert_raises(AbairtClient::Error) do
      NativeQuestion.ask!(user: @learner, audio: @audio, abairt: Abairt.new(AbairtClient::Error.new("down")))
    end
    assert_equal 0, NativeQuestion.count
  end

  test "refreshing picks up the answer" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")

    question.refresh!(abairt: Abairt.new({ "status" => "answered", "answer_audio_url" => "https://abairt.test/a7", "answered_at" => Time.current.iso8601 }))

    assert question.reload.answered?
    assert_equal "https://abairt.test/a7", question.answer_audio_url
    assert question.new_answer?
  end

  test "an answered question isn't asked about again" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "answered")

    question.refresh!(abairt: Abairt.new(RuntimeError.new("shouldn't be asked")))

    assert question.answered?
  end
end
