require "test_helper"

class Mcp::VocabularySourceTest < ActiveSupport::TestCase
  test "create_record accepts a source note for a vocabulary word" do
    lesson = vocabulary_items(:dog).lesson
    res = Mcp::Tools::CreateRecord.call(
      resource: "vocabulary_items",
      attributes: { "lesson_id" => lesson.id, "irish" => "tástáil", "english" => "test", "source" => "Erris p. 45" },
      server_context: {}
    )
    assert_not res.error?
    assert_equal "Erris p. 45", VocabularyItem.find_by!(irish: "tástáil").source
  end

  test "an over-long source is rejected with a validation error" do
    lesson = vocabulary_items(:dog).lesson
    res = Mcp::Tools::CreateRecord.call(
      resource: "vocabulary_items",
      attributes: { "lesson_id" => lesson.id, "irish" => "tástáil", "english" => "test", "source" => "a" * 201 },
      server_context: {}
    )
    assert res.error?
    assert_nil VocabularyItem.find_by(irish: "tástáil")
  end

  test "update_record sets and clears a source note" do
    item = vocabulary_items(:dog)
    Mcp::Tools::UpdateRecord.call(resource: "vocabulary_items", id: item.id, attributes: { "source" => "Tourmakeady p. 9" }, server_context: {})
    assert_equal "Tourmakeady p. 9", item.reload.source
    Mcp::Tools::UpdateRecord.call(resource: "vocabulary_items", id: item.id, attributes: { "source" => " " }, server_context: {})
    assert_nil item.reload.source
  end
end
