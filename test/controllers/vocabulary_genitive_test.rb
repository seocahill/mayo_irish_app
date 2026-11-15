require "test_helper"

class VocabularyGenitiveTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:one)
    @item = vocabulary_items(:dog)
  end

  test "a designer can set the genitive, and learners see it" do
    sign_in_as(users(:admin))
    patch lesson_path(@lesson), params: { lesson: { vocabulary_items_attributes: { "0" => { id: @item.id, genitive: "GEN-TEST" } } } }
    assert_equal "GEN-TEST", @item.reload.genitive

    sign_in_as(users(:two))
    get lesson_path(@lesson)
    assert_response :success
    assert_match "GEN-TEST", @response.body
    assert_match "Genitive", @response.body
  end

  test "the editor offers a genitive field" do
    sign_in_as(users(:admin))
    get edit_lesson_path(@lesson)
    assert_response :success
    assert_select "input[name$='[genitive]']"
  end

  test "the tutor is told the genitive when there is one" do
    @item.update!(genitive: "GEN-TEST")
    assert_includes LessonContext.new(@lesson).send(:vocabulary_text, [ @item ]), "gen. GEN-TEST"
  end

  test "items without a genitive read as before" do
    assert_nil @item.genitive
    refute_includes LessonContext.new(@lesson).send(:vocabulary_text, [ @item ]), "gen."
  end

  test "the new-row template includes the genitive" do
    sign_in_as(users(:admin))
    get edit_lesson_path(@lesson)
    assert_match "[NEW_INDEX][genitive]", @response.body
  end
end
