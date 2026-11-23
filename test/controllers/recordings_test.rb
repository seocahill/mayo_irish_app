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

  test "offers to carry on from the learner's own saved place, kept on the device" do
    stub_recording

    with_abairt_token { get recording_path(15) }

    assert_select "[data-controller~=listening-place]" do |wrapper|
      assert_equal "#{users(:two).id}:15", wrapper.first["data-listening-place-key-value"]
      assert_equal "true", wrapper.first["data-listening-place-offer-value"]
      assert_equal I18n.t("recordings.show.carry_on", time: "__TIME__"), wrapper.first["data-listening-place-label-value"]
    end
    assert_select "audio[data-listening-place-target=audio][data-action~='timeupdate->listening-place#track']"
    assert_select "audio[data-action~='pause->listening-place#save'][data-action~='ended->listening-place#clear']"
    assert_select "[data-action~='listening-place:skipped->transcript#skipped']"
    assert_select "button[hidden][data-listening-place-target=carryOn][data-action='listening-place#carryOn']",
                  text: I18n.t("recordings.show.carry_on_fallback")
  end

  test "opened at a clip's phrase, it starts there and doesn't offer the saved place" do
    stub_recording

    with_abairt_token { get recording_path(15, t: 12.0) }

    assert_select "[data-controller~=listening-place][data-listening-place-offer-value=false]"
  end

  test "a line of the conversation can be repeated" do
    stub_recording

    with_abairt_token { get recording_path(15) }

    assert_select "button[data-transcript-target=repeatToggle][data-action='transcript#toggleRepeat'][aria-pressed=false]",
                  text: I18n.t("recordings.show.repeat")
  end

  test "the lock screen gets the recording's title, speakers and the transcript lines" do
    stub_recording

    with_abairt_token { get recording_path(15) }

    assert_select "[data-controller~=media-session]" do |wrapper|
      assert_equal "A Story", wrapper.first["data-media-session-title-value"]
      assert_equal "A Speaker", wrapper.first["data-media-session-artist-value"]
      assert_equal I18n.t("app_name"), wrapper.first["data-media-session-album-value"]
      assert_equal "/icon.png", wrapper.first["data-media-session-artwork-value"]
    end
    assert_select "[data-action~='media-session:skipped->transcript#skipped']"
    assert_select "audio[data-media-session-target=audio]"
    assert_select "button[data-media-session-target=line][data-start='12.0']"
  end

  test "a recording with no named speaker and no title still has lock-screen words" do
    stub_request(:get, RECORDING).to_return(status: 200, body: {
      id: 15, title: "", audio_url: "https://abairt.test/story.mp3", lines: []
    }.to_json)

    with_abairt_token { get recording_path(15) }

    assert_select "[data-media-session-title-value=?][data-media-session-artist-value=?]",
                  I18n.t("recordings.show.untitled"), I18n.t("recordings.show.speaker_unknown")
    assert_select "[data-media-session-target=line]", false
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

  test "the Irish words can be hidden to listen first, with each line still there to tap" do
    stub_recording

    with_abairt_token { get recording_path(15) }

    assert_select "button[data-transcript-target=wordsToggle][data-action='transcript#toggleWords'][aria-pressed=false]",
                  text: I18n.t("recordings.show.hide_words")
    assert_select "ol.group[data-transcript-target=lines]" do
      assert_select "button[data-start='12.0'][data-action='transcript#seek']" do
        assert_select "span[lang=ga][data-transcript-target=irish]", text: "one madra two"
        assert_select "span.sr-only[hidden][data-transcript-target=hiddenLine]", text: I18n.t("recordings.show.hidden_line", time: "0:12")
      end
    end
  end

  test "a recording with no transcript has no words to hide" do
    stub_request(:get, RECORDING).to_return(status: 200, body: { id: 15, title: "A Story", audio_url: "https://abairt.test/story.mp3", lines: [] }.to_json)

    with_abairt_token { get recording_path(15) }

    assert_select "[data-transcript-target=wordsToggle]", count: 0
  end

  test "a whole recording has Back 5 s, and a skip lets go of a repeated line" do
    stub_recording

    with_abairt_token { get recording_path(15) }

    assert_select "[data-controller~=playback][data-action~='playback:skipped->transcript#skipped']" do
      assert_select "button[data-action='playback#back']", text: I18n.t("shared.playback_back.text")
      assert_select "[data-playback-keys]"
      assert_select "button[data-action='playback#cycleSpeed'] [data-playback-target=speedLabel]", text: "1×"
      assert_select "[data-playback-target=speedStatus][aria-live=polite]"
    end
  end

  test "the learner can say they followed a whole recording, their own word kept with their listening" do
    users(:two).listening_times.create!(abairt_recording_id: 15, seconds: 300, updated_at: 2.days.ago)

    patch recording_follow_path(15), params: { followed: true }

    assert_redirected_to recording_path(15, anchor: "followed")
    assert_equal I18n.t("recording_follows.update.followed"), flash[:notice]
    time = users(:two).listening_times.sole
    assert time.followed
    assert_equal 300, time.seconds
    assert_in_delta 2.days.ago, time.updated_at, 1.minute, "saying so isn't listening, so the last-listened time stays"

    patch recording_follow_path(15), params: { followed: false }

    assert_equal false, time.reload.followed
    assert_equal I18n.t("recording_follows.update.not_yet"), flash[:notice]
  end

  test "saying so before any listening time is reported still keeps the answer" do
    patch recording_follow_path(15), params: { followed: "true" }

    time = users(:two).listening_times.sole
    assert time.followed
    assert_equal 0, time.seconds
  end

  test "only offered recordings can be marked as followed" do
    patch recording_follow_path(99), params: { followed: true }
    assert_response :not_found

    @clip.hide!(by: users(:admin))
    patch recording_follow_path(15), params: { followed: true }
    assert_response :not_found
    assert_empty users(:two).listening_times
  end

  test "the recording page asks whether the learner followed it and shows their answer" do
    stub_recording

    with_abairt_token { get recording_path(15) }

    assert_select "section#followed h2", text: I18n.t("recordings.show.followed_heading")
    assert_select "section#followed form[action=?]", recording_follow_path(15), count: 2
    assert_select "section#followed button[aria-pressed=false]", count: 2
    assert_select "[data-testid=followed-answer]", count: 0

    users(:two).listening_times.create!(abairt_recording_id: 15, seconds: 60, followed: true)
    with_abairt_token { get recording_path(15) }

    assert_select "[data-testid=followed-answer]", text: I18n.t("recordings.show.you_followed")
    assert_select "section#followed button[aria-pressed=true]", text: I18n.t("recordings.show.i_followed")
  end

  test "Your listening shows which conversations the learner followed" do
    users(:two).listening_times.create!(abairt_recording_id: 15, seconds: 60, followed: true)
    users(:two).listening_times.create!(abairt_recording_id: 16, seconds: 0, followed: false)
    users(:two).listening_times.create!(abairt_recording_id: 17, seconds: 90)

    get listens_path

    assert_select "#conversations-heading + ul li", count: 3
    assert_select "#conversations-heading + ul span", text: I18n.t("listens.index.followed"), count: 1
    assert_select "#conversations-heading + ul span", text: I18n.t("listens.index.not_followed_yet"), count: 1
    assert_select "#conversations-heading + ul", text: /No listening yet/
  end
end
