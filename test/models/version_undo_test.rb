require "test_helper"

class VersionUndoTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @word = vocabulary_items(:dog)
  end

  def last_version = PaperTrail::Version.where(lesson_id: @lesson.id).order(:id).last

  test "edits are filed under the lesson of the record they belong to" do
    @word.update!(english: "hound")

    version = last_version
    assert_equal [ "VocabularyItem", @word.id, "update" ], [ version.item_type, version.item_id, version.event ]
  end

  test "undoing an edit puts back the previous value" do
    original = @word.english
    @word.update!(english: "hound")

    VersionUndo.new(last_version).call

    assert_equal original, @word.reload.english
  end

  test "the undo is itself recorded, so it can be undone" do
    original = @word.english
    @word.update!(english: "hound")
    VersionUndo.new(last_version).call

    VersionUndo.new(last_version).call

    assert_equal "hound", @word.reload.english
    assert_not_equal original, @word.english
  end

  test "undoing a creation removes the record" do
    word = @lesson.vocabulary_items.create!(irish: "capall", english: "horse")

    VersionUndo.new(last_version).call

    assert_not VocabularyItem.exists?(word.id)
  end

  test "undoing a deletion brings the record back" do
    @word.destroy!

    VersionUndo.new(last_version).call

    assert_equal @word.irish, VocabularyItem.find(@word.id).irish
  end

  test "a deletion that has already been undone is not undoable again" do
    @word.destroy!
    version = last_version
    VersionUndo.new(version).call

    again = PaperTrail::Version.find(version.id)
    assert_not VersionUndo.new(again).possible?
    assert_raises(ActiveRecord::RecordNotFound) { VersionUndo.new(again).call }
  end

  test "rich text edits are tracked and undoable" do
    @lesson.update!(vocabulary_notes_content: "<div>first</div>")
    @lesson.update!(vocabulary_notes_content: "<div>second</div>")
    version = last_version
    assert_equal "ActionText::RichText", version.item_type

    VersionUndo.new(version).call

    assert_match "first", @lesson.reload.vocabulary_notes_content.to_s
  end

  test "review marks and touches are not part of the history" do
    assert_no_difference -> { PaperTrail::Version.count } do
      @lesson.mark_reviewed(by: users(:admin))
    end
  end
end
