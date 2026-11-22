require "test_helper"

class WhereTaughtControllerTest < ActionDispatch::IntegrationTest
  test "admins see each matching word with its lesson, recording, clips and questions" do
    sign_in_as(users(:admin))
    item = vocabulary_items(:dog)
    item.update!(audio_url: "https://example.org/a.mp3")
    QuizQuestion.create!(lesson: item.lesson, source: item, direction: "ga_en", prompt: "madra", answer: "dog", distractors: [])

    get where_taught_path(q: "madra")

    assert_response :success
    assert_select "#where-taught-item-#{item.id}" do
      assert_select "span[lang=ga]", text: "madra"
      assert_select "a[href='#{lesson_path(item.lesson)}']"
      assert_select "a[href='#{edit_lesson_path(item.lesson)}']"
      assert_select "p", text: /Recorded/
      assert_select "p", text: /No listening clips/
      assert_select "p", text: /1 review question/
    end
  end

  test "lists lessons that use the word in a phrase or an exercise" do
    sign_in_as(users(:admin))
    lesson = lessons(:one)
    Phrase.create!(lesson: lesson, irish: "Tá madra agam", english: "I have a dog")
    Exercise.create!(lesson: lesson, number: 99, prompt: "Translate madra", answer: "dog")

    get where_taught_path(q: "madra")

    assert_select "#where-taught-phrase-lessons a[href='#{lesson_path(lesson)}']"
    assert_select "#where-taught-exercise-lessons a[href='#{lesson_path(lesson)}']"
  end

  test "an empty page shows only the form, a short or unmatched word says so" do
    sign_in_as(users(:admin))

    get where_taught_path
    assert_response :success
    assert_select "input[name=q]"
    assert_select "#where-taught-words", false

    get where_taught_path(q: "m")
    assert_select "#where-taught-short"

    get where_taught_path(q: "zzqx")
    assert_select "#where-taught-none"
    assert_select "#where-taught-phrase-lessons", text: "None."
  end

  test "looking up writes nothing" do
    sign_in_as(users(:admin))
    assert_no_changes(-> { [ VocabularyItem.count, Phrase.count, QuizQuestion.count ] }) do
      get where_taught_path(q: "madra")
    end
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))
    get where_taught_path(q: "madra")
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get where_taught_path
    assert_response :redirect
  end
end
