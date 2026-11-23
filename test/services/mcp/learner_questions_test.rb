require "test_helper"

class Mcp::LearnerQuestionsTest < ActiveSupport::TestCase
  def call(**args)
    res = Mcp::Tools::LearnerQuestions.call(server_context: {}, **args)
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  def question(id, at:, **attrs)
    NativeQuestion.create!(user: users(:two), abairt_question_id: id, status: "waiting", created_at: at,
                           audio_url: "https://abairt.test/q#{id}", **attrs)
  end

  test "lists questions newest first with the answer link and saved ideas, never the learner or their recording" do
    older = question(1, at: 2.days.ago, lesson: lessons(:one), status: "answered", answered_at: 1.day.ago,
                        answer_audio_url: "https://abairt.test/a1")
    idea = older.save_as_idea!("Lesson 1 needs more on tá", origin: "admin")
    newer = question(2, at: 1.hour.ago)

    res, data = call

    assert_not res.error?
    assert_equal [ 2, 1 ], [ data["total"], data["answered"] ]
    assert_equal [ newer.id, older.id ], data["questions"].map { |q| q["id"] }
    first, second = data["questions"]
    assert_equal [ "waiting", nil, nil, [] ], [ first["status"], first["lesson"], first["answer_audio_url"], first["ideas"] ]
    assert_equal "answered", second["status"]
    assert_equal lessons(:one).number, second.dig("lesson", "number")
    assert_equal "https://abairt.test/a1", second["answer_audio_url"]
    assert_equal [ { "id" => idea.id, "title" => idea.title, "status" => "captured" } ], second["ideas"]
    text = res.content.first[:text]
    assert_not_includes text, "abairt.test/q"
    assert_not_includes text, users(:two).email_address
  end

  test "can keep to one lesson" do
    question(1, at: 1.day.ago, lesson: lessons(:one))
    question(2, at: 1.hour.ago)

    _, data = call(lesson: lessons(:one).number)

    assert_equal 1, data["total"]
    assert_equal [ lessons(:one).number ], data["questions"].map { |q| q.dig("lesson", "number") }
  end

  test "an unknown lesson is an error" do
    res, = call(lesson: 9999)

    assert res.error?
    assert_includes res.content.first[:text], "no lesson 9999"
  end

  test "can keep to questions no idea has been saved from" do
    question(1, at: 1.day.ago).save_as_idea!("Done", origin: "admin")
    fresh = question(2, at: 1.hour.ago)

    _, data = call(without_idea: true)

    assert_equal [ fresh.id ], data["questions"].map { |q| q["id"] }
    assert_equal 1, data["total"]
  end

  test "an answer link that isn't https is left out" do
    question(1, at: 1.hour.ago, status: "answered", answer_audio_url: "http://abairt.test/a1")

    _, data = call

    assert_nil data["questions"].first["answer_audio_url"]
  end

  test "limit is kept between one and the maximum" do
    30.times { |i| question(100 + i, at: i.minutes.ago) }

    assert_equal 1, call(limit: 0).last["questions"].size
    assert_equal Mcp::Tools::LearnerQuestions::MAX_LIMIT, call(limit: 99).last["questions"].size
    assert_equal Mcp::Tools::LearnerQuestions::DEFAULT_LIMIT, call.last["questions"].size
    assert_equal 30, call.last["total"]
  end

  test "changes nothing" do
    question(1, at: 1.hour.ago, status: "sent")

    assert_no_changes -> { [ NativeQuestion.maximum(:updated_at), CourseProposal.count, ProposalEvidence.count ] } do
      call
    end
  end
end
