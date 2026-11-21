require "test_helper"

class VocabularySourceTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:one)
    @item = vocabulary_items(:dog)
  end

  test "a designer can set a source and learners see it beside the word" do
    sign_in_as(users(:admin))
    patch lesson_path(@lesson), params: { lesson: { vocabulary_items_attributes: { "0" => { id: @item.id, source: "Erris p. 45" } } } }
    assert_equal "Erris p. 45", @item.reload.source

    sign_in_as(users(:two))
    get lesson_path(@lesson)
    assert_response :success
    assert_match "Source: Erris p. 45", @response.body
  end

  test "words with no source show no source line" do
    sign_in_as(users(:two))
    get lesson_path(@lesson)
    assert_response :success
    assert_no_match "Source:", @response.body
  end

  test "the editor offers a source field, also in the new-row template" do
    sign_in_as(users(:admin))
    get edit_lesson_path(@lesson)
    assert_select "input[name$='[source]']"
    assert_match "[NEW_INDEX][source]", @response.body
  end

  test "a source is escaped, trimmed, stored as nil when blank, and capped at 200 characters" do
    @item.update!(source: "  <b>x</b>  ")
    assert_equal "<b>x</b>", @item.source
    sign_in_as(users(:two))
    get lesson_path(@lesson)
    assert_match "&lt;b&gt;x&lt;/b&gt;", @response.body

    @item.update!(source: "   ")
    assert_nil @item.reload.source
    assert_not @item.update(source: "a" * 201)
  end
end
