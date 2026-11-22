require "test_helper"

class SpeakingDayTest < ActiveSupport::TestCase
  setup { @user = users(:two) }

  test "recordings add to the day" do
    travel_to Time.zone.parse("2026-11-18 12:00") do
      SpeakingDay.add(@user, 12)
      SpeakingDay.add(@user, "8")
      SpeakingDay.add(@user, 5, on: Date.new(2026, 11, 17))

      assert_equal 20, @user.speaking_days.find_by!(day: Date.new(2026, 11, 18)).seconds
      assert_equal 2, @user.speaking_days.count
    end
  end

  test "a recording left running counts for half a minute at most" do
    SpeakingDay.add(@user, 5000)
    assert_equal SpeakingDay::MAX_RECORDING, @user.speaking_days.sole.seconds
  end

  test "ignores nothing, nonsense and negative lengths" do
    SpeakingDay.add(@user, 0)
    SpeakingDay.add(@user, "abc")
    SpeakingDay.add(@user, -20)
    SpeakingDay.add(@user, nil)
    assert_empty @user.speaking_days
  end
end
