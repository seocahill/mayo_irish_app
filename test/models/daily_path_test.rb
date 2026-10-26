require "test_helper"

class DailyPathTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
    QuizQuestion.sync_for(@lesson)
  end

  test "suggests the first unfinished lesson, a tutor chat and a conversation for it" do
    items = DailyPath.new(@user).items

    assert_equal [ :foghlaim, :cleacht, :labhair ], items.map(&:level)
    assert_equal "Learn · Lesson 1", items.first.label
    assert_equal [ "/lessons/1", "/lessons/1/chat", "/lessons/1/conversation" ], items.map(&:path)
  end

  test "offers the lesson's words from Mayo speakers when there are recordings" do
    vocabulary_items(:dog).update!(audio_url: "https://abairt.com/madra.mp3")

    listen = DailyPath.new(@user).items.first

    assert_equal :eist, listen.level
    assert_equal "Hear a word from Lesson 1 said by a Mayo speaker", listen.title
    assert_equal "/lessons/1#vocabulary", listen.path
  end

  test "adds a review item with the due count and quiz link" do
    @lesson.quiz_questions.first(3).each do |question|
      QuizReview.create!(user: @user, quiz_question: question, box: 2, due_at: 1.hour.ago)
    end

    review = DailyPath.new(@user).items.first

    assert_equal :foghlaim, review.level
    assert_equal "Review · 3 due", review.label
    assert_equal "/lessons/1/quiz", review.path
  end

  test "ignores reviews that are not due yet or belong to someone else" do
    question = @lesson.quiz_questions.first
    QuizReview.create!(user: @user, quiz_question: question, box: 3, due_at: 2.days.from_now)
    QuizReview.create!(user: users(:admin), quiz_question: question, box: 2, due_at: 1.hour.ago)

    assert_equal 0, DailyPath.new(@user).due_count
  end

  test "counts known words and moves on when a lesson is complete" do
    @lesson.quiz_questions.each do |question|
      QuizReview.create!(user: @user, quiz_question: question, box: 3, due_at: 2.days.from_now)
    end
    path = DailyPath.new(@user)

    assert_equal @lesson.vocabulary_items.count, path.known_words
    assert_nil path.current_lesson
    assert_empty path.items
  end

  test "does not suggest draft lessons to learners" do
    @lesson.update!(published: false)

    assert_nil DailyPath.new(@user).current_lesson
  end
end
