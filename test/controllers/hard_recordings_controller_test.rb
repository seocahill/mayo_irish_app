require "test_helper"

class HardRecordingsControllerTest < ActionDispatch::IntegrationTest
  test "admins see each conversation learners couldn't follow, with its figures and links" do
    item = vocabulary_items(:dog)
    ListeningClip.create!(vocabulary_item: item, abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                          audio_url: "https://clips.test/1", word_count: 3, abairt_recording_id: 15, abairt_recording_title: "A Story")
    users(:two).listening_times.create!(abairt_recording_id: 15, seconds: 60, followed: false)
    sign_in_as(users(:admin))

    get hard_recordings_path

    assert_response :success
    assert_select "#hard-recording-15" do
      assert_select "p.font-semibold", text: "A Story"
      assert_select "dd", text: "1 of 1 who answered (100%)"
      assert_select "dd", text: "0"
      assert_select "a[href='#{lesson_path(item.lesson)}']"
      assert_select "a[href='#{recording_path(15)}']"
      assert_select "a[href='#{recording_path(15, anchor: "questions")}']"
    end
  end

  test "a conversation reached only from a draft lesson is marked Draft" do
    draft = Lesson.create!(number: 98, title: "Draft lesson", published: false)
    item = draft.vocabulary_items.create!(irish: "focal", english: "word")
    ListeningClip.create!(vocabulary_item: item, abairt_entry_id: 2, irish: "one madra two", english: "a phrase",
                          audio_url: "https://clips.test/2", word_count: 3, abairt_recording_id: 16)
    users(:two).listening_times.create!(abairt_recording_id: 16, seconds: 60, followed: false)
    sign_in_as(users(:admin))

    get hard_recordings_path

    assert_select "#hard-recording-16 .chip", text: "Draft"
  end

  test "course tools links to it" do
    sign_in_as(users(:admin))

    get course_tools_path

    assert_select "a[href=?]", hard_recordings_path
  end

  test "with nothing to show it says so" do
    sign_in_as(users(:admin))

    get hard_recordings_path

    assert_select "#hard-recordings-none"
    assert_select "#hard-recordings", false
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))

    get hard_recordings_path

    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get hard_recordings_path

    assert_redirected_to new_session_path
  end
end
