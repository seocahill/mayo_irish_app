require "test_helper"

class LessonChatControllerTest < ActionDispatch::IntegrationTest
  RECOGNITION_URL = "https://api.abair.ie/v4/recognition/batch".freeze

  def recording(bytes = "webm-bytes")
    Rack::Test::UploadedFile.new(StringIO.new(bytes), "audio/webm", original_filename: "speech.webm")
  end

  def tutor_messages = users(:two).chat_sessions.tutor.where(lesson: @lesson).last.chat_messages

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

  test "the tutor chat says its replies are written by AI and marks each one" do
    stub_openai_chat("What is the word for dog?")
    post message_lesson_chat_path(@lesson), params: { message: "start" }

    follow_redirect!

    assert_select "[role=note]", text: /written by AI/
    assert_select "#chat-messages .chip", text: "AI-generated", count: 1
  end

  test "with the speech service set up, the learner can answer aloud" do
    with_abair_key { get lesson_chat_path(@lesson) }

    assert_select "form[enctype='multipart/form-data'][data-controller~=speech-input]" do
      assert_select "button[data-action='speech-input#toggle'][aria-label=?]", I18n.t("lesson_chat.show.record")
      assert_select "input[type=file][name=audio][data-speech-input-target=audio]"
      assert_select "input[type=hidden][name=spoken_seconds][data-speech-input-target=spokenSeconds]"
      assert_select "[data-speech-input-target=status]", text: I18n.t("lesson_chat.show.record_hint")
    end
  end

  test "without the speech service there is no microphone" do
    get lesson_chat_path(@lesson)

    assert_select "[data-action='speech-input#toggle']", count: 0
    assert_select "form textarea[name=message]"
  end

  test "a spoken answer is what ABAIR heard, goes to the tutor, and counts as speaking" do
    asr = stub_request(:post, RECOGNITION_URL).to_return(status: 200, body: { text: "madra" }.to_json)
    stub_openai_chat("Well done.")

    with_abair_key { post message_lesson_chat_path(@lesson), params: { audio: recording, spoken_seconds: "4" } }

    assert_requested asr
    assert_requested(:post, OpenaiTestHelper::CHAT_URL) { |request| JSON.parse(request.body)["messages"].last["content"] == "madra" }
    assert_equal [ [ "user", "madra", 4 ], [ "assistant", "Well done.", nil ] ], tutor_messages.map { |m| [ m.role, m.content, m.spoken_seconds ] }
    assert_equal 4, ChatMessage.spoken_by(users(:two)).sum(:spoken_seconds)
    assert_redirected_to lesson_chat_path(@lesson)
  end

  test "a typed answer isn't counted as speaking, and a spoken one is capped at the recogniser's limit" do
    stub_request(:post, RECOGNITION_URL).to_return(status: 200, body: { text: "madra" }.to_json)
    stub_openai_chat("Well done.")

    with_abair_key do
      post message_lesson_chat_path(@lesson), params: { message: "dog", spoken_seconds: "5" }
      post message_lesson_chat_path(@lesson), params: { audio: recording, spoken_seconds: "600" }
    end

    assert_equal [ nil, 30 ], tutor_messages.where(role: "user").map(&:spoken_seconds)
  end

  test "a spoken answer says it is what the recogniser heard; a typed one doesn't" do
    get lesson_chat_path(@lesson)
    session = ChatSession.tutor.last # the one this browser is using
    session.chat_messages.create!(role: "user", content: "typed words")
    session.chat_messages.create!(role: "user", content: "madra", spoken_seconds: 3)
    get lesson_chat_path(@lesson)

    assert_select "[data-testid=spoken-turn]", count: 1 do
      assert_select "p[aria-describedby=heard-as-note]", text: I18n.t("lesson_chat.show.heard_as")
      assert_select "div[lang=ga]", text: "madra"
    end
    assert_select "#heard-as-note", text: I18n.t("lesson_chat.show.heard_as_note")
    assert_select ".flex.justify-end > div", text: /typed words/
  end

  test "with only typed answers there is no Heard as note" do
    get lesson_chat_path(@lesson)

    assert_select "[data-testid=heard-as-note]", count: 0
  end

  test "a recording with nothing in it is not sent to the tutor" do
    stub_request(:post, RECOGNITION_URL).to_return(status: 200, body: { text: " " }.to_json)

    with_abair_key { post message_lesson_chat_path(@lesson), params: { audio: recording } }

    assert_redirected_to lesson_chat_path(@lesson)
    assert_equal I18n.t("lesson_chat.message.not_heard"), flash[:alert]
    assert_not_requested :post, OpenaiTestHelper::CHAT_URL
  end

  test "says so when the speech service is down" do
    stub_request(:post, RECOGNITION_URL).to_return(status: 503, body: "{}")

    with_abair_key { post message_lesson_chat_path(@lesson), params: { audio: recording } }

    assert_equal I18n.t("lesson_chat.message.no_speech_service"), flash[:alert]
    assert_not_requested :post, OpenaiTestHelper::CHAT_URL
  end

  test "a recording over the size limit is turned away" do
    with_abair_key { post message_lesson_chat_path(@lesson), params: { audio: recording("x" * (AbairClient::MAX_AUDIO_BYTES + 1)) } }

    assert_equal I18n.t("lesson_chat.message.too_long"), flash[:alert]
    assert_not_requested :post, RECOGNITION_URL
  end

  test "the tutor is told spoken answers come through a recogniser, whatever the lesson's own instructions" do
    @lesson.update!(tutor_prompt: "Ask about the dog.")
    stub_openai_chat("a question in English")

    post message_lesson_chat_path(@lesson), params: { message: "start" }

    assert_requested(:post, OpenaiTestHelper::CHAT_URL) do |request|
      system = JSON.parse(request.body)["messages"].first["content"].squish
      system.include?("Ask about the dog.") && system.include?("never mark an answer wrong for those alone")
    end
  end

  test "a learner never carries on someone else's tutor chat in the same browser" do
    stub_openai_chat("Well done.")
    post message_lesson_chat_path(@lesson), params: { message: "mine" }
    first = ChatSession.tutor.last

    sign_in_as(users(:admin))
    get lesson_chat_path(@lesson)

    assert_response :success
    assert_select "#chat-messages", text: /mine/, count: 0
    assert_equal users(:admin), ChatSession.tutor.last.user
    assert_not_equal first, ChatSession.tutor.last
  end

  test "learners can't practise lessons they can't see" do
    @lesson.update!(published: false)

    get lesson_chat_path(@lesson)

    assert_response :not_found
  end

  test "a non-file audio parameter is ignored, not an error" do
    post message_lesson_chat_path(@lesson), params: { audio: "not a file" }

    assert_redirected_to lesson_chat_path(@lesson)
    assert_not_requested :post, OpenaiTestHelper::CHAT_URL
  end

  test "any Irish in the tutor chat can be selected and heard, saying the voice is synthetic" do
    with_abair_key { get lesson_chat_path(@lesson) }

    assert_select "[data-controller=speakable][data-speakable-src-value=?]", speech_path do
      assert_select "[data-speakable-target=selection] button", text: /Hear it \(synthetic\)/
      assert_select "#chat-messages[data-action=?]", "scroll->speakable#hide"
      assert_select "form[data-speakable-ignore] textarea"
    end
    assert_select "[data-synthetic-note]", text: /synthetic voice, not a Mayo speaker/
  end

  test "without a speech key the tutor chat offers no read-aloud" do
    with_abair_key("") { get lesson_chat_path(@lesson) }

    assert_select "[data-controller=speakable]", count: 0
    assert_select "[data-synthetic-note]", count: 0
    assert_select "#chat-messages"
  end
end
