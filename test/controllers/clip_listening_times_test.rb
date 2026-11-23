require "test_helper"

# Time spent playing a listening clip counts towards minutes listened.
class ClipListeningTimesTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    @clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                                  audio_url: "https://clips.test/1", speaker_name: "A Speaker", word_count: 3)
    sign_in_as(@learner)
  end

  test "the clip page reports how long it has been playing" do
    get listening_clip_path(@clip)

    assert_select "[data-controller~='listen-time'][data-listen-time-report-url-value=?]", listening_clip_listening_time_path(@clip) do
      assert_select "audio[data-listen-time-target=audio][data-playback-target=audio]" \
                    "[data-action~='timeupdate->listen-time#count'][data-action~='pause->listen-time#report']"
    end
  end

  test "reported seconds count this week, in Your weeks and in the lifetime total" do
    travel_to Time.zone.parse("2026-11-18 12:00") do
      @learner.listening_times.create!(abairt_recording_id: 7, seconds: 120)
      ListeningDay.add(@learner, 120)

      patch listening_clip_listening_time_path(@clip), params: { seconds: 30 }
      patch listening_clip_listening_time_path(@clip), params: { seconds: 30 }

      assert_response :no_content
      day = @learner.listening_days.sole
      assert_equal [ 180, 60 ], [ day.seconds, day.clip_seconds ]
      assert_equal 3, ListeningDay.minutes_this_week(@learner)
      assert_equal 3, ListeningTime.minutes_for(@learner)
      assert_equal 3, LearnerWeeks.new(@learner).weeks.first.minutes_listened
    end
  end

  test "one report counts at most a minute, and nonsense counts nothing" do
    patch listening_clip_listening_time_path(@clip), params: { seconds: 5000 }
    patch listening_clip_listening_time_path(@clip), params: { seconds: -20 }
    patch listening_clip_listening_time_path(@clip), params: { seconds: "abc" }
    patch listening_clip_listening_time_path(@clip), params: { seconds: [ 30 ] }
    patch listening_clip_listening_time_path(@clip), params: { seconds: { a: 1 } }

    assert_equal ListeningTime::MAX_REPORT, @learner.listening_days.sole.clip_seconds
  end

  test "a hidden clip's time isn't counted for a learner" do
    @clip.update!(status: "hidden")

    patch listening_clip_listening_time_path(@clip), params: { seconds: 30 }

    assert_response :not_found
    assert_empty @learner.listening_days
  end

  test "signed out, nothing is counted" do
    delete session_path

    patch listening_clip_listening_time_path(@clip), params: { seconds: 30 }

    assert_redirected_to new_session_path
    assert_empty @learner.listening_days
  end
end
