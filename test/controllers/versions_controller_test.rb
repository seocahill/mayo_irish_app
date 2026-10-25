require "test_helper"

class VersionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:one)
    @word = vocabulary_items(:dog)
  end

  test "learners can't see a lesson's history" do
    sign_in_as(users(:two))

    get lesson_versions_path(@lesson)

    assert_redirected_to root_path
  end

  test "admins see edits with who made them" do
    sign_in_as(users(:admin))
    patch lesson_path(@lesson), params: { lesson: { title: "A new title" } }

    get lesson_versions_path(@lesson)

    assert_response :success
    assert_select "ins", text: "A new title"
    assert_match users(:admin).email_address, response.body
  end

  test "admins can undo a change" do
    sign_in_as(users(:admin))
    original = @lesson.title
    patch lesson_path(@lesson), params: { lesson: { title: "A new title" } }
    version = PaperTrail::Version.where(lesson_id: @lesson.id).order(:id).last

    post lesson_version_undo_path(@lesson, version)

    assert_redirected_to lesson_versions_path(@lesson)
    assert_equal original, @lesson.reload.title
  end

  test "a change that can't be undone says why" do
    sign_in_as(users(:admin))
    number = @lesson.number
    @lesson.update!(number: 500)
    version = PaperTrail::Version.where(lesson_id: @lesson.id).order(:id).last
    Lesson.create!(number: number, title: "Taken", position: 99)

    post lesson_version_undo_path(@lesson.reload, version)

    assert_redirected_to lesson_versions_path(@lesson)
    assert_match "Couldn't undo", flash[:alert]
    assert_equal 500, @lesson.reload.number
  end

  test "learners can't undo" do
    sign_in_as(users(:two))
    @word.update!(english: "hound")
    version = PaperTrail::Version.where(lesson_id: @lesson.id).order(:id).last

    post lesson_version_undo_path(@lesson, version)

    assert_equal "hound", @word.reload.english
  end

  test "the editor links to the history" do
    sign_in_as(users(:admin))

    get edit_lesson_path(@lesson)

    assert_select "a[href=?]", lesson_versions_path(@lesson)
  end
end
