require "test_helper"

class LessonTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @user = users(:two)
    QuizQuestion.sync_for(@lesson)
  end

  test "progress total is the vocabulary word count, even before questions are answered" do
    progress = @lesson.progress_for(@user)
    assert_equal @lesson.vocabulary_items.count, progress.total
    assert_equal 0, progress.known
  end

  test "a word counts as known only once all its directions are known" do
    word = @lesson.vocabulary_items.first
    questions = @lesson.quiz_questions.where(source: word).to_a
    assert_equal 2, questions.size

    # Only one direction known -> word not yet counted.
    QuizReview.create!(user: @user, quiz_question: questions.first, box: 3)
    assert_equal 0, @lesson.progress_for(@user).known

    # Both directions known -> word counts.
    QuizReview.create!(user: @user, quiz_question: questions.last, box: 2)
    assert_equal 1, @lesson.progress_for(@user).known
  end

  test "progress is complete when every word is known" do
    @lesson.quiz_questions.find_each do |q|
      QuizReview.create!(user: @user, quiz_question: q, box: 5)
    end
    progress = @lesson.progress_for(@user)
    assert progress.complete?
    assert_equal 100, progress.pct
  end

  test "the intro video comes from the saved link" do
    assert_nil @lesson.intro_video

    @lesson.update!(intro_video_url: "https://youtu.be/dQw4w9WgXcQ")

    assert_equal "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ", @lesson.intro_video.src
  end

  test "an intro video link that cannot be embedded is invalid" do
    @lesson.intro_video_url = "https://example.com/not-a-video"

    assert_not @lesson.valid?
    assert_includes @lesson.errors[:intro_video_url].first, "supported video"
  end

  test "a blank intro video link is fine" do
    @lesson.intro_video_url = ""

    assert @lesson.valid?
  end

  test "drafts need review until someone reviews them" do
    draft = Lesson.create!(number: 9300, title: "Draft", position: 9300, published: false)
    assert draft.needs_review?

    draft.mark_reviewed(by: users(:admin))

    assert draft.reviewed?
    assert_equal users(:admin), draft.reviewed_by
    assert_not draft.needs_review?

    draft.clear_review
    assert draft.needs_review?
  end

  test "published lessons never need review" do
    assert_not @lesson.needs_review?
  end
end
