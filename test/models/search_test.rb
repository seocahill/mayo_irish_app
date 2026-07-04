require "test_helper"

class SearchTest < ActiveSupport::TestCase
  setup do
    # Fixtures are loaded without callbacks, so build the index from them.
    SearchIndex.rebuild!
    @lesson = lessons(:one)
  end

  test "blank and whitespace queries return nothing" do
    assert_empty Search.new("").results
    assert_empty Search.new("   ").results
    assert_empty Search.new(nil).results
  end

  test "finds vocabulary by English word" do
    titles = Search.new("house").results.map(&:title)
    assert_includes titles, "teach — house"
  end

  test "finds vocabulary by Irish word" do
    titles = Search.new("madra").results.map(&:title)
    assert_includes titles, "madra — dog"
  end

  test "prefix matching finds partial words" do
    titles = Search.new("lea").results.map(&:title)
    assert_includes titles, "leabhar — book"
  end

  test "Irish search is diacritic-insensitive both ways" do
    item = @lesson.vocabulary_items.create!(irish: "fáilte", english: "welcome", position: 99)

    assert_includes Search.new("failte").results.map(&:record_id), item.id,
                    "typing without a fada should match fada content"
    assert_includes Search.new("fáilte").results.map(&:record_id), item.id,
                    "typing with a fada should still match"
  end

  test "results carry the lesson number for linking" do
    result = Search.new("madra").results.find { |r| r.title == "madra — dog" }
    assert_equal @lesson.number, result.lesson_number
  end

  test "snippets highlight matched terms with sentinels" do
    result = Search.new("house").results.find { |r| r.record_type == "VocabularyItem" }
    assert_includes result.snippet, Search::HIGHLIGHT_OPEN
    assert_includes result.snippet, Search::HIGHLIGHT_CLOSE
  end

  test "FTS operators and punctuation in the query are treated as literals" do
    assert_nothing_raised do
      Search.new("AND OR NEAR *").results
      Search.new(%q{"; DROP TABLE search_documents; --}).results
    end
    # The table is still intact after an injection-shaped query.
    assert_operator ApplicationRecord.connection.select_value(
      "SELECT COUNT(*) FROM search_documents"
    ), :>, 0
  end

  test "editing a record updates the index" do
    item = @lesson.vocabulary_items.create!(irish: "ainmhí", english: "beast", position: 98)
    assert_includes Search.new("beast").results.map(&:record_id), item.id

    item.update!(english: "creature")
    assert_includes Search.new("creature").results.map(&:record_id), item.id
    assert_empty Search.new("beast").results.select { |r| r.record_id == item.id },
                 "the old text should no longer match after an edit"
  end

  test "destroying a record removes it from the index" do
    item = @lesson.vocabulary_items.create!(irish: "gealach", english: "moon", position: 97)
    assert_includes Search.new("gealach").results.map(&:record_id), item.id

    item.destroy!
    assert_empty Search.new("gealach").results
  end
end
