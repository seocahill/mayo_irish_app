require "test_helper"

class QuizReviewTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    QuizQuestion.sync_for(lessons(:one))
    @question = QuizQuestion.first
    @review = QuizReview.new(user: @user, quiz_question: @question)
  end

  test "a correct answer promotes the box and counts as known" do
    assert_not @review.known?
    @review.record_answer(correct: true)
    assert_equal 2, @review.box
    assert @review.known?
    assert_equal 1, @review.times_correct
  end

  test "consecutive correct answers climb to but cap at the top box" do
    6.times { @review.record_answer(correct: true) }
    assert_equal QuizReview::MAX_BOX, @review.box
  end

  test "a wrong answer drops the item back to box 1 and clears known status" do
    3.times { @review.record_answer(correct: true) }
    assert @review.known?

    @review.record_answer(correct: false)
    assert_equal 1, @review.box
    assert_not @review.known?
    assert_equal 1, @review.times_wrong
  end

  test "due_at is scheduled from the box interval" do
    freeze_time do
      @review.record_answer(correct: true) # box 2 -> 1 day
      assert_in_delta 1.day.from_now, @review.due_at, 1.second
    end
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
end
