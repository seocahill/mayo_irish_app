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
  end
end
