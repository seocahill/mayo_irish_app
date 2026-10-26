require "test_helper"

class LessonIntroVideoTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @learner = users(:two)
    @lesson = lessons(:one)
  end

  # ── learners ──────────────────────────────────────────────

  test "learners see a youtube intro video as a privacy-friendly embed" do
    @lesson.update!(intro_video_url: "https://youtu.be/dQw4w9WgXcQ")
    sign_in_as(@learner)

    get lesson_path(@lesson)

    assert_response :success
    assert_select "iframe[src=?]", "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
  end

  test "learners see a video file in a video element" do
    @lesson.update!(intro_video_url: "https://assets.abairt.com/darren-reagan-bofield.mp4")
    sign_in_as(@learner)

    get lesson_path(@lesson)

    assert_select "video[src=?][controls]", "https://assets.abairt.com/darren-reagan-bofield.mp4"
  end

  test "the transcript sits under the video" do
    @lesson.update!(intro_video_url: "https://youtu.be/dQw4w9WgXcQ", intro_video_transcript: "Welcome to the lesson.")
    sign_in_as(@learner)

    get lesson_path(@lesson)

    assert_select "details", text: /Welcome to the lesson\./
  end

  test "no video section when there is no video" do
    sign_in_as(@learner)

    get lesson_path(@lesson)

    assert_select "iframe", count: 0
    assert_select "video", count: 0
  end

  test "learners cannot update a lesson" do
    sign_in_as(@learner)

    patch lesson_path(@lesson), params: { lesson: { intro_video_url: "https://youtu.be/dQw4w9WgXcQ" } }

    assert_nil @lesson.reload.intro_video_url
  end

  # ── admins ────────────────────────────────────────────────

  test "an admin saves the intro video and transcript" do
    sign_in_as(@admin)

    patch lesson_path(@lesson), params: { lesson: { intro_video_url: "https://vimeo.com/123456789", intro_video_transcript: "Hello." } }

    assert_redirected_to lesson_path(@lesson)
    @lesson.reload
    assert_equal "https://vimeo.com/123456789", @lesson.intro_video_url
    assert_equal "Hello.", @lesson.intro_video_transcript
  end

  test "an unsupported link is rejected with a message" do
    sign_in_as(@admin)

    patch lesson_path(@lesson), params: { lesson: { intro_video_url: "https://example.com/page" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /supported video/
    assert_nil @lesson.reload.intro_video_url
  end

  test "the editor previews the saved video" do
    @lesson.update!(intro_video_url: "https://youtu.be/dQw4w9WgXcQ")
    sign_in_as(@admin)

    get edit_lesson_path(@lesson)

    assert_response :success
    assert_select "iframe[src=?]", "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
  end

  # ── preview as learner ──────────────────────────────────────

  test "admins see edit controls normally and not in preview" do
    sign_in_as(@admin)

    get lesson_path(@lesson)
    assert_select "a[href=?]", edit_lesson_path(@lesson)
    assert_select "a[href=?]", lesson_path(@lesson, preview: 1)

    get lesson_path(@lesson, preview: 1)
    assert_select "a[href=?]", edit_lesson_path(@lesson), count: 0
    assert_select "a[href=?]", lesson_path(@lesson), text: "Exit preview"
  end

  test "the preview parameter does nothing for learners" do
    sign_in_as(@learner)

    get lesson_path(@lesson, preview: 1)

    assert_select "a", text: "Exit preview", count: 0
  end

  # ── review status ──────────────────────────────────────────

  test "an admin marks a lesson reviewed and clears it" do
    sign_in_as(@admin)

    post lesson_review_path(@lesson)
    assert_redirected_to edit_lesson_path(@lesson)
    assert @lesson.reload.reviewed?
    assert_equal @admin, @lesson.reviewed_by

    delete lesson_review_path(@lesson)
    assert_not @lesson.reload.reviewed?
  end

  test "learners cannot mark a lesson reviewed" do
    sign_in_as(@learner)

    post lesson_review_path(@lesson)

    assert_not @lesson.reload.reviewed?
  end

  test "draft lessons that need review are flagged for admins only" do
    Lesson.create!(number: 9301, title: "Unchecked draft", position: 9301, published: false)

    sign_in_as(@admin)
    get lessons_path
    assert_select "span.chip", text: "Needs review"

    sign_in_as(@learner)
    get lessons_path
    assert_select "span.chip", text: "Needs review", count: 0
  end
end
