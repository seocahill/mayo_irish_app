require "test_helper"

class VocabularyGapsTest < ActiveSupport::TestCase
  test "a complete word is not listed and a blank audio_url counts as missing" do
    item = vocabulary_items(:dog)
    item.update!(genitive: "madra", plural: "madraí", audio_url: "")
    assert_equal [ :recording ], VocabularyGaps.missing_for(item)
    item.update!(audio_url: "https://example.com/a.mp3")
    assert_empty VocabularyGaps.missing_for(item)
    assert_not_includes VocabularyGaps.new.rows.flat_map(&:items), item
  end

  test "totals count each kind of gap" do
    totals = VocabularyGaps.new.totals
    assert_equal VocabularyItem.where(genitive: [ nil, "" ]).count, totals[:genitive]
  end

  test "whole words match, plurals count, substrings do not" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "tired")
    VocabularyItem.create!(lesson: lesson, irish: "b", english: "Reds")
    colours = VocabularyGaps.new.thin_themes.find { |t| t.name == "Colours" }
    assert_equal 1, colours.count
  end

  test "a theme with three words drops off, two stay, thinnest first" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    %w[red green].each_with_index { |c, i| VocabularyItem.create!(lesson: lesson, irish: "x#{i}", english: c) }
    themes = VocabularyGaps.new.thin_themes
    assert_equal 2, themes.find { |t| t.name == "Colours" }.count
    assert_equal themes.map(&:count), themes.map(&:count).sort
    VocabularyItem.create!(lesson: lesson, irish: "x9", english: "blue")
    assert_nil VocabularyGaps.new.thin_themes.find { |t| t.name == "Colours" }
  end

  test "themes file is well formed" do
    raw = YAML.safe_load_file(VocabularyGaps::THEMES_FILE)
    assert raw.all? { |t| t["name"].present? && t["keywords"].present? && t["keywords"].all?(String) }
    assert_equal raw.size, raw.map { |t| t["name"] }.uniq.size
  end

  test "a lesson is silent only when none of its words has a recording" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    a = VocabularyItem.create!(lesson: lesson, irish: "a", english: "one", audio_url: "")
    VocabularyItem.create!(lesson: lesson, irish: "b", english: "two")
    assert_equal [ [ lesson, 2 ] ], VocabularyGaps.new.silent_lessons.map { |s| [ s.lesson, s.count ] }
    a.update!(audio_url: "https://example.com/a.mp3")
    assert_empty VocabularyGaps.new.silent_lessons
  end
end
