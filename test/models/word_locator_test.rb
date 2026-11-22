require "test_helper"

class WordLocatorTest < ActiveSupport::TestCase
  test "matches Irish or English, with counts" do
    item = vocabulary_items(:dog)
    QuizQuestion.create!(lesson: item.lesson, source: item, direction: "ga_en", prompt: "madra", answer: "dog", distractors: [])

    match = WordLocator.new(" DOG ").matches.sole
    assert_equal item, match.item
    assert_equal 1, match.quiz_questions
    assert_equal 0, match.listening_clips
    assert_not match.has_recording
  end

  test "matches part of an Irish word" do
    assert_equal [ vocabulary_items(:dog) ], WordLocator.new("adr").matches.map(&:item)
  end

  test "a term shorter than two letters finds nothing" do
    locator = WordLocator.new("m")
    assert_not locator.valid?
    assert_empty locator.matches
    assert_empty locator.phrase_lessons
    assert_empty locator.exercise_lessons
  end

  test "wildcards are taken literally" do
    assert_empty WordLocator.new("%_").matches
  end
end
