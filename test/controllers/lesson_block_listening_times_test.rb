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
                    "[data-action~='timeupdate->listen-time#count'][data-action~='pause->listen-time#stopped']"
    end
  end

  test "reported seconds count this week, in Your weeks and in the lifetime total" do
    travel_to Time.zone.parse("2026-11-18 12:00") do
      @learner.listening_times.create!(abairt_recording_id: 7, seconds: 60)
      ListeningDay.add(@learner, 60)

      patch lesson_block_listening_time_path(@block), params: { seconds: 30 }
      patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

      assert_response :no_content
      day = @learner.listening_days.sole
      assert_equal [ 120, 60 ], [ day.seconds, day.clip_seconds ]
      assert_equal 2, ListeningDay.minutes_this_week(@learner)
      assert_equal 2, ListeningTime.minutes_for(@learner)
      assert_equal 2, LearnerWeeks.new(@learner).weeks.first.minutes_listened
    end
  end

  test "one report counts at most a minute, and nonsense counts nothing" do
    patch lesson_block_listening_time_path(@block), params: { seconds: 5000 }
    patch lesson_block_listening_time_path(@block), params: { seconds: "abc" }
    patch lesson_block_listening_time_path(@block), params: { seconds: -20 }
    patch lesson_block_listening_time_path(@block), params: { seconds: [ 30 ] }
    patch lesson_block_listening_time_path(@block), params: { seconds: { a: 1 } }

    assert_equal ListeningTime::MAX_REPORT, @learner.listening_days.sole.clip_seconds
  end

  test "an unpublished lesson's audio isn't counted for a learner" do
    @block.lesson.update!(published: false)

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

    assert_response :not_found
    assert_empty @learner.listening_days
  end

  test "an editor's listening to a draft lesson counts, but not in View as learner" do
    @block.lesson.update!(published: false)
    sign_in_as(users(:admin))

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }
    assert_response :no_content

    get lesson_path(@block.lesson, preview: 1)
    assert_select "figure[data-controller~='playback'] audio"
    assert_select "[data-controller~='listen-time']", count: 0
    assert_select "[data-listen-time-report-url-value]", count: 0
  end

  test "the editor's block pages don't count listening" do
    sign_in_as(users(:admin))

    get edit_lesson_block_path(@block)
    assert_select "[data-controller~='listen-time']", count: 0
    get edit_lesson_path(@block.lesson)
    assert_select "[data-controller~='listen-time']", count: 0
  end

  test "an audio block with no file isn't counted" do
    @block.file.purge

    patch lesson_block_listening_time_path(@block), params: { seconds: 30 }

    assert_response :not_found
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
