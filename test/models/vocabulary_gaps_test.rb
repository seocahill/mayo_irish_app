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
end
