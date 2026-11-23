require "test_helper"

class LessonSlotTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @lesson.update!(published: false)
  end

  def add_slot(**attrs)
    @lesson.lesson_slots.create!({ slot_type: "example_sentences", spec: "3 to 5 sentences for the conditional" }.merge(attrs))
  end

  test "a slot needs a known type and an English spec" do
    assert_predicate add_slot, :open?
    assert_not @lesson.lesson_slots.new(slot_type: "poem", spec: "x").valid?
    assert_not @lesson.lesson_slots.new(slot_type: "vocabulary", spec: " ").valid?
    assert_not @lesson.lesson_slots.new(slot_type: "vocabulary", spec: "a" * (LessonSlot::SPEC_LENGTH + 1)).valid?
  end

  test "removing a slot keeps it, marked removed with who and when" do
    slot = add_slot

    assert slot.remove!(by: "admin@example.com")

    slot.reload
    assert_equal [ "removed", "admin@example.com" ], [ slot.status, slot.removed_by ]
    assert slot.removed_at
    assert_not slot.remove!(by: "someone@example.com")
    assert_equal "admin@example.com", slot.reload.removed_by
  end

  test "a draft with open slots can't be published" do
    add_slot
    add_slot(slot_type: "vocabulary", spec: "Words for the weather")

    assert_not @lesson.update(published: true)
    assert_includes @lesson.errors.full_messages.to_sentence, "2 slots are open"
    assert_not @lesson.reload.published?
  end

  test "once every slot is removed the draft can be published" do
    add_slot.remove!(by: "admin@example.com")

    assert @lesson.update(published: true)
  end

  test "other edits to a draft with open slots still save" do
    add_slot

    assert @lesson.update(title: "A new title")
  end

  test "an already published lesson with an open slot can still be edited" do
    add_slot
    @lesson.update_column(:published, true)

    assert @lesson.reload.update(title: "Still editable")
  end
end
