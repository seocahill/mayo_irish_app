require "test_helper"

class LearnerActivityTest < ActiveSupport::TestCase
  setup do
    @learner = users(:two)
    QuizQuestion.sync_for(lessons(:one))
    @question = QuizQuestion.first
  end

  test "counts this week's answers, clips and minutes spoken, and the lessons started" do
    travel_to Time.zone.parse("2026-10-28 12:00") do
      answered(at: 2.weeks.ago)
      answered
      answered
      QuizReview.create!(user: @learner, quiz_question: @question, box: 2, due_at: 1.day.from_now)
      @learner.listens.create!(listening_clip: clip, understood: true)
      3.times { spoke(30) }

      row = activity_for(@learner)

      assert_equal [ 2, 1, 2, 1 ], [ row.answers, row.clips, row.minutes_spoken, row.lessons_started ]
    end
  end

  test "last active is the latest thing the learner did" do
    travel_to Time.zone.parse("2026-10-28 12:00") do
      @learner.sessions.create!(created_at: 3.days.ago)
      answered(at: 2.days.ago)
      spoke(10, at: 1.day.ago)

      assert_equal 1.day.ago, activity_for(@learner).last_active_at
    end
  end

  test "the most recently active come first, and those yet to start last" do
    users(:admin).sessions.create!(created_at: 1.day.ago)
    answered

    emails = LearnerActivity.new(User.where(id: [ users(:admin), users(:two), users(:newcomer) ])).rows.map { |row| row.user.email_address }

    assert_equal %w[two@example.com admin@example.com newcomer@example.com], emails
  end

  test "a learner who has done nothing has no activity" do
    row = activity_for(users(:newcomer))

    assert_nil row.last_active_at
    assert_equal [ 0, 0, 0, 0 ], [ row.answers, row.clips, row.minutes_spoken, row.lessons_started ]
  end

  test "one learner's activity isn't counted for another" do
    answered
    assert_equal 0, activity_for(users(:admin)).answers
  end

  private

  def activity_for(user) = LearnerActivity.new(User.where(id: user)).rows.sole

  def answered(at: Time.current)
    @learner.review_logs.create!(quiz_question: @question, prompt: "teach", correct: true, box_before: 1, box_after: 2, answered_at: at)
  end

  def spoke(seconds, at: Time.current)
    chat = @learner.chat_sessions.find_or_create_by!(lesson: lessons(:one), kind: :conversation)
    chat.chat_messages.create!(role: "user", content: "spoken", spoken_seconds: seconds, created_at: at)
  end

  def clip
    ListeningClip.create!(vocabulary_item: vocabulary_items(:house), abairt_entry_id: 1, irish: "one teach two", english: "a phrase",
                          audio_url: "https://clips.test/1", word_count: 3)
  end
end
