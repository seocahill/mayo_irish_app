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

  test "saving a question as an idea keeps the designer's words and attaches the answer, not the learner's voice" do
    question = NativeQuestion.create!(user: users(:two), lesson: lessons(:one), abairt_question_id: 70, status: "answered",
                                      audio_url: "https://abairt.test/q70", answer_audio_url: "https://abairt.test/a70")

    idea = question.save_as_idea!("Lesson 1 never says when to use tá", origin: "admin")

    assert_equal [ "idea", "captured", "admin", "Lesson 1 never says when to use tá" ],
                 [ idea.kind, idea.status, idea.origin, idea.raw_text ]
    evidence = idea.proposal_evidence.sole
    assert_equal question, evidence.native_question
    assert_equal "https://abairt.test/a70", evidence.audio_url
    assert_includes evidence.source, "Abairt question 70"
    assert_includes evidence.source, lessons(:one).display_title
    assert_not_includes evidence.source, "q70"
    assert_equal [ idea ], question.reload.ideas
  end

  test "an unanswered question is saved without audio" do
    question = NativeQuestion.create!(user: users(:two), abairt_question_id: 71, status: "sent", audio_url: "https://abairt.test/q71")

    evidence = question.save_as_idea!("Something about numbers", origin: "admin").proposal_evidence.sole

    assert_nil evidence.audio_url
    assert_includes evidence.source, "no lesson"
  end

  test "a blank idea saves nothing" do
    question = NativeQuestion.create!(user: users(:two), abairt_question_id: 72, status: "sent")

    assert_no_difference -> { CourseProposal.count + ProposalEvidence.count } do
      assert_raises(ActiveRecord::RecordInvalid) { question.save_as_idea!("  ", origin: "admin") }
    end
  end

  test "deleting a question leaves the idea and its evidence, unlinked" do
    question = NativeQuestion.create!(user: users(:two), abairt_question_id: 73, status: "sent")
    evidence = question.save_as_idea!("Keep me", origin: "admin").proposal_evidence.sole

    question.destroy!

    assert_nil evidence.reload.native_question_id
  end

  test "an answer link that isn't https or is too long for the evidence is left out" do
    question = NativeQuestion.create!(user: users(:two), abairt_question_id: 74, status: "answered", answer_audio_url: "http://abairt.test/a74")
    assert_nil question.save_as_idea!("Plain http", origin: "admin").proposal_evidence.sole.audio_url

    question.update!(answer_audio_url: "https://abairt.test/#{"a" * 600}")
    assert_nil question.save_as_idea!("Too long", origin: "admin").proposal_evidence.last.audio_url
  end

  test "if the evidence can't be saved, neither is the idea" do
    question = NativeQuestion.create!(user: users(:two), abairt_question_id: 75, status: "sent")
    question.define_singleton_method(:evidence_source) { "" }

    assert_no_difference -> { CourseProposal.count + ProposalEvidence.count } do
      assert_raises(ActiveRecord::RecordInvalid) { question.save_as_idea!("Rolled back", origin: "admin") }
    end
  end

  test "ideas are listed in the order they were saved" do
    question = NativeQuestion.create!(user: users(:two), abairt_question_id: 76, status: "sent")
    first = question.save_as_idea!("First", origin: "admin")
    second = question.save_as_idea!("Second", origin: "admin")

    assert_equal [ first, second ], NativeQuestion.includes(proposal_evidence: :course_proposal).find(question.id).ideas
  end
end
