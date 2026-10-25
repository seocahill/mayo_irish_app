require "test_helper"

class LessonHistoryTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @word = vocabulary_items(:dog)
  end

  test "lists the newest change first, with what changed" do
    PaperTrail.request(whodunnit: users(:admin).id.to_s) do
      @word.update!(english: "hound")
    end

    entry = LessonHistory.new(@lesson).entries.first

    assert_equal "update", entry.event
    assert_equal "Word", entry.kind
    assert_equal @word.irish, entry.subject
    assert_equal users(:admin).email_address, entry.who
    assert_equal [ "English", "hound" ], entry.changes.map { |c| [ c.field, c.to ] }.first
    assert entry.undoable?
  end

  test "bookkeeping timestamps are not listed as changes" do
    @word.update!(english: "hound")

    fields = LessonHistory.new(@lesson).entries.first.changes.map(&:field)

    assert_equal [ "English" ], fields
  end

  test "rich text changes are shown as plain text excerpts" do
    @lesson.update!(vocabulary_notes_content: "<div>one</div>")
    @lesson.update!(vocabulary_notes_content: "<div><strong>two</strong></div>")

    change = LessonHistory.new(@lesson).entries.first.changes.first

    assert_equal [ "Text", "one", "two" ], [ change.field, change.from, change.to ]
  end

  test "deleted records are still named" do
    @word.destroy!

    entry = LessonHistory.new(@lesson).entries.first

    assert_equal [ "destroy", @word.irish ], [ entry.event, entry.subject ]
  end

  test "other lessons' changes are not included" do
    other = Lesson.create!(number: 99, title: "Other", position: 99)
    other.vocabulary_items.create!(irish: "x", english: "y")

    assert LessonHistory.new(@lesson).entries.none? { |e| e.subject == "x" }
  end
end
