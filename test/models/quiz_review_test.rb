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
end
