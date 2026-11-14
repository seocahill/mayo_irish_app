require "test_helper"

class QuizReviewTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    QuizQuestion.sync_for(lessons(:one))
    @question = QuizQuestion.first
    @review = QuizReview.new(user: @user, quiz_question: @question)
  end

  test "one correct answer is not enough to count as known" do
    @review.record_answer(correct: true)
    assert_equal 2, @review.box
    assert_not @review.known?
    assert_equal 1, @review.times_correct
  end

  test "repeated correct answers at growing gaps reach known and cap the box" do
    6.times do
      @review.record_answer(correct: true)
      travel_to(@review.due_at + 1.minute)
    end
    assert_equal QuizReview::MAX_BOX, @review.box
    assert @review.known?
    assert_operator @review.stability, :>=, QuizReview::KNOWN_STABILITY
  ensure
    travel_back
  end

  test "a wrong answer drops the box to 1 and clears known status" do
    @review.update!(box: 4, fsrs_state: 2, stability: 20.0, difficulty: 5.0,
                    last_reviewed_at: 20.days.ago, due_at: 1.day.ago)
    assert @review.known?

    @review.record_answer(correct: false)
    assert_equal 1, @review.box
    assert_not @review.known?
    assert_equal 1, @review.times_wrong
    assert_operator @review.stability, :<, 20.0
  end

  test "an easy rating schedules further out than good" do
    good = QuizReview.new(user: @user, quiz_question: @question).tap { |r| r.record_answer(correct: true, rating: :good) }
    easy = QuizReview.new(user: users(:admin), quiz_question: @question).tap { |r| r.record_answer(correct: true, rating: :easy) }
    assert_operator easy.due_at, :>, good.due_at
  end

  test "legacy rows seeded from a box are scheduled from that stability" do
    @review.update!(box: 5, fsrs_state: 2, stability: 21.0, difficulty: 5.0,
                    last_reviewed_at: 21.days.ago, due_at: Time.current)
    assert @review.known?
    @review.record_answer(correct: true)
    assert_operator @review.due_at, :>, 21.days.from_now
  end

  test "forecast counts what is due today, tomorrow and this week" do
    @review.update!(box: 3, fsrs_state: 2, stability: 3.0, difficulty: 5.0, due_at: 1.hour.ago)
    other = QuizQuestion.where.not(id: @question.id).first
    QuizReview.create!(user: @user, quiz_question: other, box: 3, fsrs_state: 2, stability: 3.0,
                       difficulty: 5.0, due_at: 1.day.from_now.change(hour: 12))
    forecast = QuizReview.forecast_for(@user)
    assert_equal 1, forecast[:today]
    assert_equal 1, forecast[:tomorrow]
    assert_equal 1, forecast[:week]
  end

  test "due scope returns reviews whose due_at has passed" do
    @review.record_answer(correct: true)
    @review.update!(due_at: 1.hour.ago)
    assert_includes QuizReview.due, @review
  end

  test "an answer is logged with the box before and after" do
    assert_difference -> { ReviewLog.count }, 1 do
      @review.record_answer(correct: true)
    end

    log = ReviewLog.last
    assert_equal @user, log.user
    assert_equal @question, log.quiz_question
    assert_equal @question.prompt, log.prompt
    assert log.correct
    assert_equal [ 1, 2 ], [ log.box_before, log.box_after ]
  end

  test "a wrong answer is logged as a drop back to box 1" do
    3.times { @review.record_answer(correct: true) }
    @review.record_answer(correct: false)

    log = ReviewLog.order(:id).last
    assert_not log.correct
    assert_equal [ 4, 1 ], [ log.box_before, log.box_after ]
    assert_equal 4, ReviewLog.where(user: @user).count
  end

  test "logs survive when the question is removed" do
    @review.record_answer(correct: true)
    log = ReviewLog.last

    @question.destroy

    assert_nil log.reload.quiz_question
    assert log.prompt.present?
  end

  test "a row with no review time is treated as a new card" do
    @review.update!(fsrs_state: 2, stability: 5.0, difficulty: 5.0, last_reviewed_at: nil)
    assert_nothing_raised { @review.record_answer(correct: true) }
  end

  test "forecast ignores other users and counts tomorrow and the days after" do
    other = QuizQuestion.where.not(id: @question.id).first
    attrs = { box: 3, fsrs_state: 2, stability: 3.0, difficulty: 5.0 }
    QuizReview.create!(user: @user, quiz_question: @question, due_at: Date.current.tomorrow.end_of_day, **attrs)
    QuizReview.create!(user: @user, quiz_question: other, due_at: Date.current.tomorrow.tomorrow.beginning_of_day, **attrs)
    QuizReview.create!(user: users(:admin), quiz_question: other, due_at: Date.current.tomorrow.beginning_of_day, **attrs)
    forecast = QuizReview.forecast_for(@user)
    assert_equal 1, forecast[:tomorrow]
    assert_equal 2, forecast[:week] # tomorrow plus the days after
  end
end
