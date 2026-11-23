require "test_helper"

class HardClipsControllerTest < ActionDispatch::IntegrationTest
  test "admins see each phrase learners couldn't make out, with its figures and links" do
    item = vocabulary_items(:dog)
    clip = ListeningClip.create!(vocabulary_item: item, abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                                 audio_url: "https://clips.test/1", word_count: 3, speaker_name: "Speaker A", speaker_dialect: "erris")
    users(:two).listens.create!(listening_clip: clip, understood: false)
    sign_in_as(users(:admin))

    get hard_clips_path

    assert_response :success
    assert_select "#hard-clip-#{clip.id}" do
      assert_select "p[lang=ga]", text: "one madra two"
      assert_select "p", text: "Speaker A · Erris"
      assert_select "dd", text: "1 of 1 who answered (100%)"
      assert_select "a[href='#{listening_clip_path(clip)}']"
      assert_select "a[href='#{lesson_listening_clips_path(item.lesson)}']"
      assert_select "a[href='#{lesson_path(item.lesson)}']"
    end
  end

  test "a clip with no speaker details leaves the speaker line out" do
    clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 2, irish: "one madra two",
                                 english: "a phrase", audio_url: "https://clips.test/2", word_count: 3)
    users(:two).listens.create!(listening_clip: clip, understood: false)
    sign_in_as(users(:admin))

    get hard_clips_path

    assert_select "#hard-clip-#{clip.id} p.text-xs", count: 1
  end

  test "with nothing to show it says so" do
    sign_in_as(users(:admin))

    get hard_clips_path

    assert_select "#hard-clips-none"
    assert_select "#hard-clips", false
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))

    get hard_clips_path

    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get hard_clips_path

    assert_redirected_to new_session_path
  end
end
