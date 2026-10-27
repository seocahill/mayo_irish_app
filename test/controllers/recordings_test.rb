require "test_helper"

# Listening through a whole Abairt recording, with its transcript following along.
class RecordingsTest < ActionDispatch::IntegrationTest
  RECORDING = "https://abairt.com/api/voice_recordings/15"

  setup do
    @clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                                  audio_url: "https://clips.test/1", word_count: 3, abairt_recording_id: 15, abairt_recording_title: "A Story", starts_at: 12.0)
    sign_in_as(users(:two))
  end

  def stub_recording(status: 200)
    stub_request(:get, RECORDING).to_return(status: status, body: {
      id: 15, title: "A Story", audio_url: "https://abairt.test/story.mp3", dialect_region: "erris",
      lines: [ { irish: "one madra two", translation: "a phrase", start: 12.0, end: 13.5, speaker: { name: "A Speaker" } } ]
    }.to_json)
  end

  test "plays the recording with its transcript, a little before the clip's phrase" do
    stub_recording

    with_abairt_token { get recording_path(15, t: 12.0) }

    assert_response :success
    assert_select "h1", text: "A Story"
    assert_select "audio[src=?]", "https://abairt.test/story.mp3"
    assert_select "[data-transcript-start-value=?]", "7.0"
    assert_select "button[data-start='12.0'] span[lang=ga]", text: "one madra two"
  end

  test "the clip page leads to the whole conversation" do
    get listening_clip_path(@clip)

    assert_select "a[href=?]", recording_path(15, t: 12.0)
  end

  test "says so when Abairt can't be reached" do
    stub_recording(status: 500)

    with_abairt_token { get recording_path(15) }

    assert_select "p", text: I18n.t("recordings.show.unavailable")
  end

  test "only recordings behind the course's clips are offered" do
    get recording_path(99)
    assert_response :not_found

    @clip.hide!(by: users(:admin))
    get recording_path(15)
    assert_response :not_found
  end

  test "the page adds up how long the learner listens, a report at a time" do
    2.times { patch recording_listening_time_path(15), params: { seconds: 30 } }
    patch recording_listening_time_path(15), params: { seconds: 5000 }

    assert_response :no_content
    assert_equal 120, users(:two).listening_times.sole.seconds
  end

  test "listening time is only kept for offered recordings" do
    patch recording_listening_time_path(99), params: { seconds: 30 }

    assert_response :not_found
    assert_empty users(:two).listening_times
  end

  test "home shows the minutes listened" do
    users(:two).listening_times.create!(abairt_recording_id: 15, seconds: 180)

    get root_path

    assert_select "p", text: /3\s+minutes listened/
  end
end
