require "test_helper"

class SpokenTimeTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @chat = @user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
  end

  test "adds up the learner's spoken turns, in minutes" do
    travel_to Time.zone.parse("2026-10-28 12:00") do
      said(30, at: 2.weeks.ago)
      said(30)
      said(30)
      @chat.chat_messages.create!(role: "user", content: "typed")
      @chat.chat_messages.create!(role: "assistant", content: "a reply")

      time = SpokenTime.new(@user)

      assert_equal 2, time.minutes
      assert_equal 1, time.minutes_this_week
    end
  end

  test "only counts the learner's own turns" do
    said(30)
    other = users(:admin).chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
    other.chat_messages.create!(role: "user", content: "theirs", spoken_seconds: 30)

    assert_equal 1, SpokenTime.new(@user).minutes
  end

  private

  def said(seconds, at: Time.current)
    @chat.chat_messages.create!(role: "user", content: "spoken", spoken_seconds: seconds, created_at: at)
  end
end
