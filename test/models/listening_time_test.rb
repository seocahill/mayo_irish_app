require "test_helper"

class ListeningTimeTest < ActiveSupport::TestCase
  test "this week counts only recordings listened to in the last week" do
    user = users(:admin)
    ListeningTime.where(user: user).delete_all
    ListeningTime.create!(user: user, abairt_recording_id: 1, seconds: 120)
    old = ListeningTime.create!(user: user, abairt_recording_id: 2, seconds: 180)
    old.update_columns(updated_at: 2.weeks.ago)
    assert_equal 5, ListeningTime.minutes_for(user)
    assert_equal 2, ListeningTime.minutes_this_week_for(user)
  end
end
