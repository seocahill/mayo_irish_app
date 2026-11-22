require "test_helper"

# The lesson word list marks the words this learner knows, by the same rule as
# the "words known" progress bar.
class LessonKnownWordsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
    QuizQuestion.sync_for(@lesson)
    @word = vocabulary_items(:dog)
  end

  def know(item, stability: 7.0)
    @lesson.quiz_questions.where(source: item).find_each do |q|
      QuizReview.create!(user: @user, quiz_question: q, box: 3, fsrs_state: 2, stability: stability)
    end
  end

  test "a known word is marked and others are not" do
    know(@word)
    sign_in_as(@user)

    get lesson_path(@lesson)

    assert_response :success
    assert_select "[data-test=known-word]", 1
    assert_select "td", text: /madra\s+You know this word/
  end

  test "a word with a recording has the record yourself control" do
    @word.update!(audio_url: "https://example.com/madra.mp3")
    sign_in_as(@user)

    get lesson_path(@lesson)

    assert_select "[data-controller=recorder][data-recorder-report-url-value=?]", speaking_time_path
    assert_select "#vocabulary [data-testid=record-yourself-note]", text: I18n.t("shared.record_yourself.note"), count: 1
    assert_select "[data-controller=recorder]" do
      assert_select "button[data-action='recorder#toggle'][aria-label=?]", I18n.t("shared.record_yourself.record")
      assert_select "button[data-action='recorder#play'][disabled]"
    end
  end

  test "the ticks match the words known count on the progress bar" do
    know(@word)
    know(vocabulary_items(:house))
    sign_in_as(@user)

    get lesson_path(@lesson)

    assert_select "[data-test=known-word]", 2
    assert_equal 2, @lesson.progress_for(@user).known
    assert_match "2/#{@lesson.vocabulary_items.count}", response.body
  end

  test "a word still being learned is not marked" do
    know(@word, stability: 2.0)
    sign_in_as(@user)

    get lesson_path(@lesson)

    assert_select "[data-test=known-word]", false
  end

  test "another learner's progress does not mark words" do
    know(@word)
    sign_in_as(users(:admin))

    get lesson_path(@lesson)

    assert_select "[data-test=known-word]", false
  end
end
