require "test_helper"

class MilestonesTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @chat = @user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
  end

  test "a new learner has reached nothing and the first steps are next" do
    words, listening, conversation = Milestones.new(@user, known_words: 0).strands

    assert_nil words.reached
    assert_equal 10, words.next_step
    assert_equal 10, words.remaining
    assert_nil listening.reached
    assert_nil conversation.reached
    assert_not words.started?
  end

  test "words known show the last step reached and the next" do
    words = Milestones.new(@user, known_words: 60).strands.first

    assert_equal 50, words.reached
    assert_equal 100, words.next_step
    assert_equal 40, words.remaining
  end

  test "the top step leaves nothing next" do
    words = Milestones.new(@user, known_words: 1500).strands.first

    assert_equal 1000, words.reached
    assert words.finished?
  end

  test "listening counts minutes across recordings" do
    ListeningTime.create!(user: @user, abairt_recording_id: 1, seconds: 20 * 60)

    listening = Milestones.new(@user, known_words: 0).strands.second

    assert_equal 15, listening.reached
    assert_equal 30, listening.next_step
  end

  test "conversation uses the longest single conversation, not the total" do
    other = @user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
    7.times { @chat.chat_messages.create!(role: "user", content: "a", spoken_seconds: 30) }
    4.times { other.chat_messages.create!(role: "user", content: "b", spoken_seconds: 30) }
    4.times { other.chat_messages.create!(role: "user", content: "c", spoken_seconds: 30) }

    conversation = Milestones.new(@user, known_words: 0).strands.third

    assert_equal 3, conversation.reached
    assert_equal 5, conversation.next_step
  end
end
