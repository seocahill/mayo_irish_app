require "test_helper"

# Time spent playing a lesson's own audio counts towards minutes listened.
class LessonBlockListeningTimesTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    @block = lesson_blocks(:one)
    @block.update!(block_type: "audio")
    @block.file.attach(io: StringIO.new("x"), filename: "a.mp3", content_type: "audio/mpeg")
    sign_in_as(@learner)
  end

  test "the lesson's audio player reports how long it has been playing" do
    get lesson_path(@block.lesson)

    assert_select "figure[data-controller~='listen-time'][data-listen-time-report-url-value=?]", lesson_block_listening_time_path(@block) do
      assert_select "audio[data-listen-time-target=audio][data-playback-target=audio]" \
                    "[data-action~='timeupdate->listen-time#count'][data-action~='pause->listen-time#report']"
    end
  end

  test "reported seconds count this week and in the lifetime total" do
    @learner.listening_times.create!(abairt_recording_id: 7, seconds: 60)
    ListeningDay.add(@learner, 60)

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }
    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

    assert_response :no_content
    day = @learner.listening_days.sole
    assert_equal [ 120, 60 ], [ day.seconds, day.clip_seconds ]
    assert_equal 2, ListeningDay.minutes_this_week(@learner)
    assert_equal 2, ListeningTime.minutes_for(@learner)
  end

  test "one report counts at most a minute, and nonsense counts nothing" do
    patch lesson_block_listening_time_path(@block), params: { seconds: 5000 }
    patch lesson_block_listening_time_path(@block), params: { seconds: "abc" }
    patch lesson_block_listening_time_path(@block), params: { seconds: [ 30 ] }

    assert_equal ListeningTime::MAX_REPORT, @learner.listening_days.sole.clip_seconds
  end

  test "an unpublished lesson's audio isn't counted for a learner" do
    @block.lesson.update!(published: false)

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

    assert_response :not_found
    assert_empty @learner.listening_days
  end

  test "only audio blocks count" do
    @block.update!(block_type: "text")

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

    assert_response :not_found
    assert_empty @learner.listening_days
  end

  test "signed out, nothing is counted" do
    delete session_path

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

    assert_redirected_to new_session_path
    assert_empty @learner.listening_days
  end
end
