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

  test "themes with fewer than three matching words are listed, thinnest first" do
    themes = VocabularyGaps.new.thin_themes
    assert themes.all? { |t| t.count < VocabularyGaps::THIN }
    assert_equal themes.map(&:count), themes.map(&:count).sort
    colours = themes.find { |t| t.name == "Colours" }
    assert_equal 0, colours.count if VocabularyItem.where("lower(english) LIKE '%red%'").none?
  end

  test "a theme with enough matching words drops off the list" do
    lesson = Lesson.first
    %w[red green blue].each_with_index do |c, i|
      VocabularyItem.create!(lesson: lesson, irish: "x#{i}", english: c)
    end
    assert_nil VocabularyGaps.new.thin_themes.find { |t| t.name == "Colours" }
  end
end
