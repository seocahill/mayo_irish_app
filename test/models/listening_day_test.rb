require "test_helper"

class ListeningDayTest < ActiveSupport::TestCase
  setup { @user = users(:two) }

  test "reports add to the day, and this week only counts this week" do
    travel_to Time.zone.parse("2026-11-18 12:00") do
      ListeningDay.add(@user, 120, on: Date.new(2026, 11, 10))
      ListeningDay.add(@user, 60)
      ListeningDay.add(@user, 60)

      assert_equal 2, ListeningDay.minutes_this_week(@user)
      assert_equal 1, @user.listening_days.where(day: Date.new(2026, 11, 18)).count
    end
  end

  test "ignores nothing-to-add" do
    ListeningDay.add(@user, 0)
    assert_empty @user.listening_days
  end

  test "ListeningTime#add keeps the day total with the clamped seconds" do
    time = @user.listening_times.create!(abairt_recording_id: 7)
    time.add(5000)
    assert_equal ListeningTime::MAX_REPORT, @user.listening_days.sole.seconds
  end
end
