require "test_helper"

class Mcp::SearchCourseTest < ActiveSupport::TestCase
  Admin = Struct.new(:email_address, :admin?)

  setup { SearchIndex.rebuild! }

  def run_tool(user: Admin.new("darren@example.com", true), **args)
    res = Mcp::Tools::SearchCourse.call(server_context: { user: user }, **args)
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  test "finds vocabulary and marks the match in bold" do
    _, body = run_tool(query: "madra")
    hit = body["results"].find { |r| r["title"] == "madra — dog" }
    assert hit, "expected madra in #{body["results"].inspect}"
    assert_equal "VocabularyItem", hit["type"]
    assert_equal lessons(:one).number, hit["lesson_number"]
    assert_includes hit["snippet"], "**"
    assert_no_match(/[\u0002\u0003]/, hit["snippet"])
  end

  test "rejects a blank query" do
    assert run_tool(query: "  ").first.error?
    assert run_tool(query: "?!").first.error?
  end

  test "limit caps the results and total counts them all" do
    3.times { |i| lessons(:one).vocabulary_items.create!(irish: "bádóir#{i}", english: "boatman #{i}", position: 100 + i) }
    _, body = run_tool(query: "boatman", limit: 2)
    assert_equal 2, body["results"].size
    assert_equal 3, body["total"]
    assert_equal false, body["truncated"]
  end

  test "says when the search stopped at its cap" do
    (Search::MAX_RESULTS + 1).times { |i| lessons(:one).vocabulary_items.create!(irish: "currach#{i}", english: "currach boat #{i}", position: 200 + i) }
    _, body = run_tool(query: "currach")
    assert_equal Search::MAX_RESULTS, body["total"]
    assert_equal true, body["truncated"]
    assert_equal Mcp::Tools::SearchCourse::DEFAULT_LIMIT, body["results"].size
  end

  test "drafts are found for admins only" do
    draft = Lesson.create!(number: 900, title: "Gortbhreac draft", position: 900, published: false)
    SearchIndex.rebuild!
    _, body = run_tool(query: "Gortbhreac")
    assert_includes body["results"].map { |r| r["lesson_number"] }, draft.number
    _, body = run_tool(query: "Gortbhreac", user: Admin.new("x@example.com", false))
    assert_empty body["results"]
  end

  test "reads only" do
    assert_no_changes -> { [ Lesson.count, VocabularyItem.count, Lesson.maximum(:updated_at) ] } do
      run_tool(query: "madra")
    end
  end
end
