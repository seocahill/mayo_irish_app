require "test_helper"

class RecordingSuggestionTest < ActiveSupport::TestCase
  setup do
    @item = vocabulary_items(:dog)
    @editor = users(:admin)
  end

  def suggestion(id, checked: true, item: @item)
    item.recording_suggestions.create!(abairt_entry_id: id, irish: item.irish, audio_url: "https://clips.test/#{id}", speaker_name: "Speaker #{id}", check_passed: checked)
  end

  test "approving makes it the word's recording, credited, and sets the others aside" do
    chosen, other = suggestion(1), suggestion(2)

    chosen.approve!(by: @editor)

    assert_equal [ "https://clips.test/1", "Speaker 1" ], @item.reload.values_at(:audio_url, :audio_credit)
    assert chosen.reload.approved?
    assert other.reload.rejected?
    assert_equal @editor, chosen.reviewed_by
  end

  test "approving the checked ones takes the best per word and skips words already done" do
    house = vocabulary_items(:house)
    first, _second = suggestion(1), suggestion(2)
    suggestion(3, checked: false, item: house)
    water = vocabulary_items(:water)
    suggestion(4, item: water).approve!(by: @editor)
    suggestion(5, item: water)

    approved = RecordingSuggestion.approve_checked!([ @item, house, water ], by: @editor)

    assert_equal 1, approved
    assert first.reload.approved?
    assert_nil house.reload.audio_credit
    assert_equal "Speaker 4", water.reload.audio_credit
  end
end
