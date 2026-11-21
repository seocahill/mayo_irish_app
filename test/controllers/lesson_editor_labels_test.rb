require "test_helper"

class LessonEditorLabelsTest < ActionDispatch::IntegrationTest
  test "vocabulary table selects and delete buttons have accessible names, in rows and the template" do
    lesson = lessons(:one)
    lesson.vocabulary_items.create!(irish: "madra", english: "dog")
    sign_in_as(users(:admin))
    get edit_lesson_path(lesson)
    assert_response :success
    assert_select "tr.vocab-row select[name$='[gender]'][aria-label]"
    assert_select "tr.vocab-row select[name$='[part_of_speech]'][aria-label]"
    assert_select "tr.vocab-row button[data-action='click->vocab-editor#removeRow'][aria-label]"
    assert_select "template#vocab-row-template select[aria-label]", 2
    assert_select "template#vocab-row-template button[aria-label]"
  end
end
