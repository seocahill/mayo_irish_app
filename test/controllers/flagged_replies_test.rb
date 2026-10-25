require "test_helper"

# Flagging a comhrá reply, the editor's list of flagged replies, and replies read aloud.
class FlaggedRepliesTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    @session = @learner.chat_sessions.conversation.create!(lesson: lessons(:one))
    @said = @session.chat_messages.create!(role: "user", content: "what the learner said")
    @reply = @session.chat_messages.create!(role: "assistant", content: "reply in irish", english: "the reply in english")
  end

  test "a learner flags a reply in their own conversation" do
    sign_in_as(@learner)

    post chat_message_flag_path(@reply)

    assert @reply.reload.flagged?
    assert_redirected_to lesson_conversation_path(lessons(:one))
  end

  test "nobody else can flag it" do
    sign_in_as(users(:newcomer))

    post chat_message_flag_path(@reply)

    assert_response :not_found
    assert_not @reply.reload.flagged?
  end

  test "an admin sees flagged replies with what prompted them, and dismisses them" do
    @reply.flag!
    sign_in_as(users(:admin))

    get lessons_path
    assert_select "a[href=?]", flagged_replies_path

    get flagged_replies_path
    assert_response :success
    assert_select "p", text: "what the learner said"
    assert_select "[lang=ga]", text: "reply in irish"

    delete flagged_reply_path(@reply)
    assert_not @reply.reload.flagged?
    assert_redirected_to flagged_replies_path
  end

  test "learners can't see the list" do
    sign_in_as(@learner)

    get flagged_replies_path

    assert_redirected_to root_path
  end

  test "a reply is read aloud for the learner whose conversation it is" do
    stub_abair_synthesis(audio: "wav-bytes")
    sign_in_as(@learner)

    with_abair_key { get chat_message_pronunciation_path(@reply) }

    assert_response :success
    assert_equal "wav-bytes", response.body
  end

  test "nobody else can play it, and learners' own lines aren't spoken" do
    sign_in_as(users(:newcomer))
    with_abair_key { get chat_message_pronunciation_path(@reply) }
    assert_response :not_found

    sign_in_as(@learner)
    with_abair_key { get chat_message_pronunciation_path(@said) }
    assert_response :not_found
  end
end
