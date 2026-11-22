require "test_helper"

class SpeakingTimesTest < ActionDispatch::IntegrationTest
  test "recording yourself counts towards the day's speaking, length only" do
    sign_in_as(users(:two))

    post speaking_time_path, params: { seconds: 7 }
    post speaking_time_path, params: { seconds: 900 }

    assert_response :no_content
    assert_equal 7 + SpeakingDay::MAX_RECORDING, users(:two).speaking_days.sole.seconds
  end

  test "needs a signed-in learner" do
    post speaking_time_path, params: { seconds: 7 }

    assert_redirected_to new_session_path
    assert_equal 0, SpeakingDay.count
  end
end
