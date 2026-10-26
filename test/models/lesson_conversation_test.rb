require "test_helper"

class LessonConversationTest < ActiveSupport::TestCase
  # Stands in for AbairS2sClient: records the messages and answers with `text`.
  class Abair
    attr_reader :requests

    def initialize(text) = (@text = text) && (@requests = [])

    def reply(messages)
      @requests << messages
      raise @text if @text.is_a?(Exception)

      @text
    end
  end

  # Stands in for the OpenAI client: records the parameters and answers with `content`.
  class Openai
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
    @unused_openai = Openai.new(RuntimeError.new("OpenAI shouldn't be asked"))
  end

  def reply_json(irish: "reply in irish", english: "the reply in english", note: nil)
    { irish: irish, english: english, note: note }.to_json
  end

  def conversation(abair: Abair.new(reply_json), openai: @unused_openai)
    LessonConversation.new(@chat_session, abair: abair, openai: openai)
  end

  test "saves what the learner said and ABAIR's reply together" do
    reply = conversation(abair: Abair.new(reply_json(note: "a tip"))).reply_to("what the learner said")

    assert @chat_session.persisted?
    assert_equal [ %w[user what\ the\ learner\ said], %w[assistant reply\ in\ irish] ],
      @chat_session.chat_messages.reload.map { |m| [ m.role, m.content ] }
    assert_equal [ "the reply in english", "a tip", "abair" ], [ reply.english, reply.note, reply.source ]
  end

  test "gives ABAIR the brief lesson context and the learner's words" do
    abair = Abair.new(reply_json)

    conversation(abair: abair).reply_to("hello")

    system, said = abair.requests.sole
    assert_equal "system", system[:role]
    assert_includes system[:content], LessonContext.new(lessons(:one)).brief
    assert_equal({ role: "user", content: "hello" }, said)
  end

  test "opens the conversation when the learner hasn't said anything" do
    abair = Abair.new(reply_json)

    conversation(abair: abair).reply_to(nil)

    assert_equal [ "system" ], abair.requests.sole.pluck(:role)
    assert_equal [ "assistant" ], @chat_session.chat_messages.reload.map(&:role)
  end

  test "earlier replies go back in the shape they came in" do
    conversation.reply_to("first")
    abair = Abair.new(reply_json)

    LessonConversation.new(@chat_session.reload, abair: abair, openai: @unused_openai).reply_to("second")

    messages = abair.requests.sole
    assert_equal %w[system user assistant user], messages.pluck(:role)
    assert_equal "reply in irish", JSON.parse(messages[2][:content])["irish"]
  end

  test "takes the JSON out of whatever else ABAIR says around it" do
    reply = conversation(abair: Abair.new("Here you go:\n```json\n#{reply_json}\n```")).reply_to("hello")

    assert_equal "reply in irish", reply.content
  end

  test "asks OpenAI when ABAIR fails or its reply is unusable" do
    [ AbairS2sClient::Error.new("down"), "no json here", reply_json(irish: "") ].each do |abair_says|
      openai = Openai.new(reply_json(irish: "from openai"))

      reply = conversation(abair: Abair.new(abair_says), openai: openai).reply_to("hello")

      assert_equal [ "from openai", "openai" ], [ reply.content, reply.source ]
      assert_equal "json_schema", openai.requests.sole[:response_format][:type]
    end
  end

  test "when neither gives a reply, nothing is saved" do
    [ "not json", reply_json(irish: ""), Faraday::ConnectionFailed.new("down") ].each do |openai_says|
      assert_raises(LessonConversation::Error) do
        conversation(abair: Abair.new(AbairS2sClient::Error.new("down")), openai: Openai.new(openai_says)).reply_to("hello")
      end
    end

    assert @chat_session.new_record?
    assert_equal 0, ChatMessage.count
  end

  test "long input is cut short" do
    conversation.reply_to("x" * 900)

    assert_equal LessonConversation::MAX_INPUT_CHARACTERS, @chat_session.chat_messages.first.content.length
  end
end
