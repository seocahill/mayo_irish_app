require "test_helper"

class LearnerWeeksTest < ActiveSupport::TestCase
  setup do
    @learner = users(:two)
    QuizQuestion.sync_for(lessons(:one))
    @question = QuizQuestion.first
  end

  test "splits answers, clips and minutes spoken into weeks, newest first" do
    travel_to Time.zone.parse("2026-10-28 12:00") do
      answered(correct: true)
      answered(correct: false)
      answered(correct: true, at: 1.week.ago)
      answered(correct: true, at: 20.weeks.ago)
      @learner.listens.create!(listening_clip: clip, understood: true, created_at: 1.week.ago)
      chat = @learner.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
      2.times { chat.chat_messages.create!(role: "user", content: "spoken", spoken_seconds: 30) }

      this_week, last_week = LearnerWeeks.new(@learner).weeks

      assert_equal [ Date.new(2026, 10, 26), 2, 1, 0, 1 ], this_week.to_h.values_at(:starts_on, :answers, :correct, :clips, :minutes_spoken)
      assert_equal [ Date.new(2026, 10, 19), 1, 1, 1, 0 ], last_week.to_h.values_at(:starts_on, :answers, :correct, :clips, :minutes_spoken)
    end
  end

  test "covers eight weeks, quiet ones included" do
    weeks = LearnerWeeks.new(@learner).weeks

    assert_equal [ 0 ] * 8, weeks.map(&:answers)
  end

  private

  def answered(correct:, at: Time.current)
    @learner.review_logs.create!(quiz_question: @question, prompt: "teach", correct: correct, box_before: 1, box_after: 1, answered_at: at)
  end

  def clip
    ListeningClip.create!(vocabulary_item: vocabulary_items(:house), abairt_entry_id: 1, irish: "one teach two", english: "a phrase",
                          audio_url: "https://clips.test/1", word_count: 3)
  end
end
