require "test_helper"

class LessonConversationTest < ActiveSupport::TestCase
  # Records what it was asked and answers with a canned completion.
  class Client
    attr_reader :requests

    def initialize(content) = (@content = content) && (@requests = [])

    def chat(parameters:)
      @requests << parameters
      raise @content if @content.is_a?(Exception)

      { "choices" => [ { "message" => { "content" => @content } } ] }
    end
  end

  setup do
    @chat_session = users(:two).chat_sessions.conversation.build(lesson: lessons(:one))
  end

  def reply_json(irish: "reply in irish", english: "the reply in english", note: nil)
    { irish: irish, english: english, note: note }.to_json
  end

  test "saves what the learner said and the reply together" do
    client = Client.new(reply_json(note: "a tip"))

    reply = LessonConversation.new(@chat_session, client: client).reply_to("what the learner said")

    assert @chat_session.persisted?
    assert_equal [ %w[user what\ the\ learner\ said], %w[assistant reply\ in\ irish] ],
                 @chat_session.chat_messages.reload.map { |m| [ m.role, m.content ] }
    assert_equal "the reply in english", reply.english
    assert_equal "a tip", reply.note
  end

  test "asks for a structured reply, with the lesson as context" do
    client = Client.new(reply_json)

    LessonConversation.new(@chat_session, client: client).reply_to("hello")

    request = client.requests.sole
    assert_equal "json_schema", request[:response_format][:type]
    assert_includes request[:messages].first[:content], vocabulary_items(:dog).irish
    assert_equal({ role: "user", content: "hello" }, request[:messages].last)
  end

  test "opens the conversation when the learner hasn't said anything" do
    client = Client.new(reply_json)

    LessonConversation.new(@chat_session, client: client).reply_to(nil)

    assert_equal [ "system" ], client.requests.sole[:messages].map { |m| m[:role] }
    assert_equal [ "assistant" ], @chat_session.chat_messages.reload.map(&:role)
  end

  test "earlier replies go back to the model in the shape it gave them" do
    LessonConversation.new(@chat_session, client: Client.new(reply_json)).reply_to("first")
    client = Client.new(reply_json)

    LessonConversation.new(@chat_session.reload, client: client).reply_to("second")

    roles = client.requests.sole[:messages].map { |m| m[:role] }
    assert_equal %w[system user assistant user], roles
    assert_equal "reply in irish", JSON.parse(client.requests.sole[:messages][2][:content])["irish"]
  end

  test "a failed call saves nothing" do
    [ "not json", reply_json(irish: ""), Faraday::ConnectionFailed.new("down") ].each do |content|
      assert_raises(LessonConversation::Error) do
        LessonConversation.new(@chat_session, client: Client.new(content)).reply_to("hello")
      end
    end

    assert @chat_session.new_record?
    assert_equal 0, ChatMessage.count
  end

  test "long input is cut short" do
    LessonConversation.new(@chat_session, client: Client.new(reply_json)).reply_to("x" * 900)

    assert_equal LessonConversation::MAX_INPUT_CHARACTERS, @chat_session.chat_messages.first.content.length
  end
end
