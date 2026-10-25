require "test_helper"

class LessonConversationsControllerTest < ActionDispatch::IntegrationTest
  RECOGNITION_URL = "https://api.abair.ie/v4/recognition/batch".freeze

  setup do
    @lesson = lessons(:one)
    @learner = users(:two)
    sign_in_as(@learner)
  end

  def conversation = @learner.chat_sessions.conversation.where(lesson: @lesson).last

  def recording(bytes = "webm-bytes")
    Rack::Test::UploadedFile.new(StringIO.new(bytes), "audio/webm", original_filename: "speech.webm")
  end

  test "an empty conversation offers to begin, and says the replies are AI-generated" do
    get lesson_conversation_path(@lesson)

    assert_response :success
    assert_select "[role=note]", text: I18n.t("lesson_conversations.show.ai_notice")
    assert_select "form[action=?] button", lesson_conversation_messages_path(@lesson), text: I18n.t("lesson_conversations.show.begin")
  end

  test "beginning gets an opening line" do
    stub_conversation_reply(irish: "an opening line")

    post lesson_conversation_messages_path(@lesson)
    follow_redirect!

    assert_equal [ "assistant" ], conversation.chat_messages.map(&:role)
    assert_select "[lang=ga]", text: "an opening line"
  end

  test "a typed message gets a reply, with its English, a note, a label and a flag button" do
    stub_conversation_reply(irish: "reply in irish", english: "the reply in english", note: "a tip")

    with_abair_key do
      post lesson_conversation_messages_path(@lesson), params: { message: "what the learner said" }
      follow_redirect!
    end

    reply = conversation.chat_messages.last
    assert_equal "reply in irish", reply.content
    assert_select "[lang=ga]", text: "reply in irish"
    assert_select "details p", text: "the reply in english"
    assert_select "p", text: "a tip"
    assert_select ".chip", text: I18n.t("lesson_conversations.show.ai_generated")
    assert_select "form[action=?]", chat_message_flag_path(reply)
    assert_select "[data-pronounce-src-value=?][data-pronounce-autoplay-value=true]", chat_message_pronunciation_path(reply)
  end

  test "the newest reply only plays on its own straight after it arrives" do
    stub_conversation_reply
    post lesson_conversation_messages_path(@lesson), params: { message: "hello" }

    with_abair_key do
      follow_redirect!
      assert_select "[data-pronounce-autoplay-value=true]"
      get lesson_conversation_path(@lesson)
    end

    assert_select "[data-controller=pronounce]"
    assert_select "[data-pronounce-autoplay-value]", count: 0
  end

  test "without an ABAIR key the conversation is typed only" do
    with_abair_key("") { get lesson_conversation_path(@lesson) }

    assert_select "[data-action='speech-input#toggle']", count: 0
  end

  test "a recording is transcribed by ABAIR and answered" do
    asr = stub_request(:post, RECOGNITION_URL).to_return(status: 200, body: { text: "what was heard" }.to_json)
    stub_conversation_reply

    with_abair_key { post lesson_conversation_messages_path(@lesson), params: { audio: recording } }

    assert_requested asr
    assert_equal [ "what was heard", "reply in irish" ], conversation.chat_messages.map(&:content)
    assert_redirected_to lesson_conversation_path(@lesson)
  end

  test "a recording with nothing in it is not sent on" do
    stub_request(:post, RECOGNITION_URL).to_return(status: 200, body: { text: " " }.to_json)

    with_abair_key { post lesson_conversation_messages_path(@lesson), params: { audio: recording } }

    assert_equal I18n.t("lesson_conversation_messages.create.not_heard"), flash[:alert]
    assert_not_requested :post, OpenaiTestHelper::S2S_URL
  end

  test "says so when the speech service is down" do
    stub_request(:post, RECOGNITION_URL).to_return(status: 503, body: "{}")

    with_abair_key { post lesson_conversation_messages_path(@lesson), params: { audio: recording } }

    assert_equal I18n.t("lesson_conversation_messages.create.no_speech_service"), flash[:alert]
  end

  test "a recording over the size limit is turned away" do
    with_abair_key { post lesson_conversation_messages_path(@lesson), params: { audio: recording("x" * (AbairClient::MAX_AUDIO_BYTES + 1)) } }

    assert_equal I18n.t("lesson_conversation_messages.create.too_long"), flash[:alert]
    assert_not_requested :post, RECOGNITION_URL
  end

  test "when ABAIR can't reply, OpenAI does" do
    stub_conversation_reply(status: 500)
    stub_openai_chat({ irish: "from openai", english: "in english", note: nil })

    post lesson_conversation_messages_path(@lesson), params: { message: "hello" }

    assert_equal [ "from openai", "openai" ], conversation.chat_messages.last.values_at(:content, :source)
  end

  test "when no reply comes back nothing is saved" do
    stub_conversation_reply(status: 500)
    stub_openai_chat(status: 500)

    post lesson_conversation_messages_path(@lesson), params: { message: "hello" }

    assert_equal I18n.t("lesson_conversation_messages.create.no_reply"), flash[:alert]
    assert_nil conversation
  end

  test "a blank message only opens an empty conversation" do
    stub_conversation_reply
    post lesson_conversation_messages_path(@lesson)

    post lesson_conversation_messages_path(@lesson), params: { message: "  " }

    assert_requested :post, OpenaiTestHelper::S2S_URL, times: 1
  end

  test "starting again keeps the old conversation for review" do
    stub_conversation_reply
    post lesson_conversation_messages_path(@lesson), params: { message: "hello" }
    old = conversation

    delete lesson_conversation_path(@lesson)

    assert_not_equal old, conversation
    assert_empty conversation.chat_messages
    assert ChatSession.exists?(old.id)
  end

  test "learners can't talk about lessons they can't see" do
    @lesson.update!(published: false)

    get lesson_conversation_path(@lesson)

    assert_response :not_found
  end

  test "the lesson page links to the conversation" do
    get lesson_path(@lesson)

    assert_select "a[href=?]", lesson_conversation_path(@lesson)
  end
end
