require "test_helper"

# Anyone can register, but until an admin approves them they should only see
# the pending page and the guide.
class PendingLearnersTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "are sent to the pending page from everything learners use" do
    lesson = lessons(:one)

    [ root_path, lessons_path, lesson_path(lesson), lesson_chat_path(lesson),
      lesson_conversation_path(lesson), lesson_quiz_path(lesson), search_path,
      native_questions_path, listens_path, new_onboarding_path ].each do |path|
      get path

      assert_redirected_to pending_approval_path, "#{path} should be closed to pending learners"
    end
  end

  test "can't post to a lesson's chat or conversation" do
    lesson = lessons(:one)

    assert_no_difference -> { ChatMessage.count } do
      post message_lesson_chat_path(lesson), params: { message: "Dia dhuit" }
      assert_redirected_to pending_approval_path

      post lesson_conversation_messages_path(lesson), params: { content: "Dia dhuit" }
      assert_redirected_to pending_approval_path
    end
  end

  test "can't authorise the claude.ai connector" do
    get oauth_authorization_path(response_type: "code", client_id: "anything")

    assert_redirected_to new_session_path
  end

  test "can see the pending page and the guide" do
    get pending_approval_path
    assert_response :success

    get guide_path
    assert_response :success
  end
end
