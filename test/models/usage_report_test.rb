require "test_helper"

class UsageReportTest < ActiveSupport::TestCase
  setup do
    QuizQuestion.sync_for(lessons(:one))
    @question = QuizQuestion.first
  end

  test "sums each week and works out who came back" do
    travel_to Time.zone.parse("2026-10-28 12:00") do
      answer(users(:one), at: 1.week.ago, correct: true)
      answer(users(:one), at: 1.hour.ago, correct: true)
      answer(users(:two), at: 1.hour.ago, correct: false)
      answer(users(:two), at: 2.hours.ago, correct: true)

      weeks = UsageReport.new.weeks
      this_week = weeks.last

      assert_equal UsageReport::WEEKS, weeks.size
      assert_equal Date.new(2026, 10, 26), this_week.starts_on
      assert_equal [ 2, 1, 100, 3, 67 ], [ this_week.active, this_week.returning, this_week.retention, this_week.answers, this_week.accuracy ]
      assert_equal [ 1, 1 ], [ weeks[-2].active, weeks[-2].answers ]
      assert_nil weeks.first.accuracy
    end
  end

  test "counts minutes listened and lessons started" do
    travel_to Time.zone.parse("2026-10-28 12:00") do
      LessonVisit.record(user: users(:one), lesson: lessons(:one))

      week = UsageReport.new.weeks.last

      assert_equal 1, week.lessons_started
      assert_equal 0, week.minutes_listened
    end
  end

  test "shows how many opened each curriculum lesson and went on to its quiz" do
    lesson = lessons(:one)
    lesson.update!(lesson_type: "curriculum", published: true)
    LessonVisit.record(user: users(:one), lesson: lesson)
    LessonVisit.record(user: users(:two), lesson: lesson)
    QuizReview.create!(user: users(:two), quiz_question: @question, box: 2, due_at: 1.day.from_now)

    stage = UsageReport.new.stages.find { |s| s.lesson == lesson }

    assert_equal [ 2, 1 ], [ stage.opened, stage.quizzed ]
  end

  private

  def answer(user, at:, correct:)
    ReviewLog.create!(user: user, quiz_question: @question, answered_at: at, correct: correct,
                      box_before: 1, box_after: 2, prompt: "x")
  end
end
