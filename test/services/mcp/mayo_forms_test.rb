require "test_helper"

class Mcp::MayoFormsTest < ActiveSupport::TestCase
  test "lists pairs with the lessons where the other form still appears" do
    item = vocabulary_items(:dog)
    DialectSubstitution.create!(other_form: item.irish, mayo_form: "gadhar", mayo_source: "Mac an Fhailigh")
    DialectSubstitution.create!(other_form: "zzzzqq", mayo_form: "xxxx")
    res = Mcp::Tools::MayoForms.call(server_context: {})
    assert_not res.error?
    pairs = JSON.parse(res.content.first[:text])["pairs"]
    dog = pairs.find { |p| p["other_form"] == item.irish }
    assert_equal "gadhar", dog["mayo_form"]
    assert_equal "Mac an Fhailigh", dog["mayo_source"]
    assert_equal [ item.lesson.number ], dog["still_in_lessons"].map { |l| l["number"] }
    assert_empty pairs.find { |p| p["other_form"] == "zzzzqq" }["still_in_lessons"]
  end

  test "finds exercise hits once per lesson" do
    lesson = lessons(:one) rescue vocabulary_items(:dog).lesson
    lesson.exercises.create!(number: "9", prompt: "uniqueformx here", answer: "uniqueformx again")
    DialectSubstitution.create!(other_form: "uniqueformx", mayo_form: "mayoy")
    res = Mcp::Tools::MayoForms.call(server_context: {})
    pair = JSON.parse(res.content.first[:text])["pairs"].first
    assert_equal [ lesson.number ], pair["still_in_lessons"].map { |l| l["number"] }
  end

  test "empty when no pairs entered" do
    assert_equal [], JSON.parse(Mcp::Tools::MayoForms.call(server_context: {}).content.first[:text])["pairs"]
  end
end
