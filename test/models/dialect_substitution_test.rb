require "test_helper"

class DialectSubstitutionTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @lesson.vocabulary_items.create!(irish: "deacair", english: "difficult", gender: "m")
    @pair = DialectSubstitution.create!(other_form: "deacair", mayo_form: "doiligh", other_source: "Ó Siadhail")
  end

  test "needs both forms" do
    assert_not DialectSubstitution.new(other_form: "x").valid?
    assert_not DialectSubstitution.new(mayo_form: "x").valid?
  end

  test "finds the other form in a lesson as a proposal and changes nothing" do
    hits = DialectSubstitution.hits_in(@lesson)

    assert_equal [ @pair ], hits.map(&:substitution)
    assert_match "deacair", hits.first.place
    assert_equal 1, @lesson.vocabulary_items.where(irish: "deacair").count
  end

  test "no pairs, no hits" do
    DialectSubstitution.delete_all

    assert_empty DialectSubstitution.hits_in(@lesson)
    assert_nil DialectSubstitution.prompt_note
  end

  test "prompt note names the Mayo form" do
    assert_match "deacair → doiligh", DialectSubstitution.prompt_note
  end
end
