require "test_helper"

class HardWordsControllerTest < ActionDispatch::IntegrationTest
  test "admins see each hard word with its figures and links" do
    lesson = lessons(:one)
    QuizQuestion.sync_for(lesson)
    item = vocabulary_items(:dog)
    question = lesson.quiz_questions.find_by!(source: item, direction: "ga_en")
    [ false, false, true ].each do |correct|
      ReviewLog.create!(user: users(:two), quiz_question: question, prompt: question.prompt, correct: correct,
                        answered_at: 1.day.ago, box_before: 1, box_after: 1)
    end
    sign_in_as(users(:admin))

    get hard_words_path

    assert_response :success
    assert_select "#hard-word-#{item.id}" do
      assert_select "span[lang=ga]", text: "madra"
      assert_select "dd", text: "2 of 3 (67%)"
      assert_select "dd", text: "1"
      assert_select "a[href='#{lesson_path(lesson)}']"
      assert_select "a[href='#{where_taught_path(q: 'madra')}']"
    end
  end

  test "with nothing to show it says so" do
    sign_in_as(users(:admin))

    get hard_words_path

    assert_select "#hard-words-none"
    assert_select "#hard-words", false
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))

    get hard_words_path

    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get hard_words_path

    assert_redirected_to new_session_path
  end
end
