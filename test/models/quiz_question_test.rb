require "test_helper"

class QuizQuestionTest < ActiveSupport::TestCase
  setup { @lesson = lessons(:one) }

  test "sync_for builds two questions per vocabulary item" do
    QuizQuestion.sync_for(@lesson)
    assert_equal @lesson.vocabulary_items.count * 2, @lesson.quiz_questions.count
    assert_equal QuizQuestion::DIRECTIONS.sort, @lesson.quiz_questions.distinct.pluck(:direction).sort
  end

  test "sync_for is idempotent" do
    QuizQuestion.sync_for(@lesson)
    assert_no_difference -> { QuizQuestion.count } do
      QuizQuestion.sync_for(@lesson)
    end
  end

  test "each question gets distractors that exclude the answer" do
    QuizQuestion.sync_for(@lesson)
    @lesson.quiz_questions.each do |q|
      assert_equal QuizQuestion::DISTRACTOR_COUNT, q.distractors.size
      assert_not_includes q.distractors, q.answer
      assert_includes q.choices, q.answer
      assert_equal q.distractors.size + 1, q.choices.size
    end
  end

  test "sync_for prunes stray questions no longer backed by lesson vocabulary" do
    QuizQuestion.sync_for(@lesson)
    # A stray row that sync_for should not keep (its source is not a current
    # vocabulary item of the lesson).
    orphan_source = @lesson.vocabulary_items.first
    # A stray row in a slot sync_for will never re-create (unknown direction).
    stray = QuizQuestion.new(
      lesson: @lesson, source: orphan_source, direction: "stray",
      prompt: "x", answer: "y", distractors: %w[a b c]
    )
    stray.save!(validate: false)

    assert_difference -> { QuizQuestion.count }, -1 do
      QuizQuestion.sync_for(@lesson)
    end
    assert_not QuizQuestion.exists?(stray.id)
  end

  test "ga_en question prompts in Irish and answers in English" do
    QuizQuestion.sync_for(@lesson)
    item = @lesson.vocabulary_items.first
    q = QuizQuestion.find_by(source: item, direction: "ga_en")
    assert_equal item.irish, q.prompt
    assert_equal item.english, q.answer
  end
end
