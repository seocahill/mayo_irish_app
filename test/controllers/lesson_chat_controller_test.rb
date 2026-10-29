require "test_helper"

class LessonChatControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:one)
    sign_in_as(users(:two))
  end

  test "the tutor is given the lesson and the rule against composing Irish" do
    stub_openai_chat("a question in English")

    post message_lesson_chat_path(@lesson), params: { message: "start" }

    assert_requested(:post, OpenaiTestHelper::CHAT_URL) do |request|
      system = JSON.parse(request.body)["messages"].first["content"]
      system.include?(LessonChatController::LANGUAGE_RULES) && system.include?(vocabulary_items(:dog).irish)
    end
    assert_equal %w[user assistant], ChatSession.tutor.last.chat_messages.map(&:role)
  end

  test "without instructions of its own, a lesson's tutor marks generously and leaves long phrases alone" do
    stub_openai_chat("a question in English")

    post message_lesson_chat_path(@lesson), params: { message: "start" }

    assert_requested(:post, OpenaiTestHelper::CHAT_URL) do |request|
      JSON.parse(request.body)["messages"].first["content"].include?(LessonChatController::DEFAULT_TUTOR_PROMPT)
    end
    assert_includes LessonChatController::DEFAULT_TUTOR_PROMPT, "Don't ask for those word for word"
    assert_includes LessonChatController::LANGUAGE_RULES, "not what the student writes"
  end

  test "the chat opens at its newest message" do
    get lesson_chat_path(@lesson)

    assert_select "#chat-messages[data-controller=scroll-to-end]"
  end

  test "the tutor chat and the conversation are kept apart" do
    stub_openai_chat("a question in English")
    users(:two).chat_sessions.conversation.create!(lesson: @lesson)

    post message_lesson_chat_path(@lesson), params: { message: "start" }

    assert_equal 1, users(:two).chat_sessions.tutor.count
    assert_empty users(:two).chat_sessions.conversation.last.chat_messages
  end
end
