require "test_helper"

class VocabularyGapsControllerTest < ActionDispatch::IntegrationTest
  test "admins see words that lack a genitive, plural or recording" do
    item = vocabulary_items(:dog)
    item.update!(genitive: "madra", plural: "madraí", audio_url: "https://example.com/a.mp3")

    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_response :success
    assert_select "#gap-totals"
    assert_select "#gaps-lesson-#{item.lesson_id}", text: /teach/
    assert_select "#gap-item-#{item.id}", count: 0
    assert_select "#gap-item-#{vocabulary_items(:house).id}", text: /genitive, plural, and recording|genitive, plural and recording/
  end

  test "admins see thin themes" do
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#thin-themes h2"
    assert_select "#thin-themes li", text: /Colours/
  end

  test "the report is read-only" do
    sign_in_as(users(:admin))
    assert_no_difference -> { VocabularyItem.count } do
      get vocabulary_gaps_path
    end
    assert_response :success
  end

  test "learners cannot see it" do
    sign_in_as(users(:two))
    get vocabulary_gaps_path
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get vocabulary_gaps_path
    assert_redirected_to new_session_path
  end

  test "lists words taught in more than one lesson" do
    other = Lesson.create!(number: 99, title: "Other", position: 99)
    other.vocabulary_items.create!(irish: "Madra", english: "dog again", position: 1)
    other.vocabulary_items.create!(irish: "Madra", english: "dog thrice", position: 2)

    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_response :success
    assert_select "#repeated-words li", text: /madra/i
    assert_select "#repeated-words li", count: 1
  end
end
