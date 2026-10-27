require "test_helper"

class NativeQuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    @lesson = lessons(:one)
    sign_in_as(@learner)
  end

  def recording = Rack::Test::UploadedFile.new(StringIO.new("recording"), "audio/webm", original_filename: "question.webm")

  test "the page offers to record a question, about a lesson if one is given" do
    with_abairt_token { get native_questions_path(lesson: @lesson.number) }

    assert_response :success
    assert_select "[data-controller=question-recorder]"
    assert_select "input[name=lesson][value=?]", @lesson.number.to_s
  end

  test "sending a question passes it to Abairt and lists it" do
    stub_request(:post, "https://abairt.com/api/questions").to_return(status: 201, body: { id: 7, status: "waiting", audio_url: "https://abairt.test/q7" }.to_json)

    with_abairt_token { post native_questions_path, params: { audio: recording, lesson: @lesson.number } }

    assert_redirected_to native_questions_path(lesson: @lesson.number)
    question = @learner.native_questions.sole
    assert_equal [ 7, @lesson ], [ question.abairt_question_id, question.lesson ]
  end

  test "nothing is sent without a recording" do
    with_abairt_token { post native_questions_path, params: { lesson: @lesson.number } }

    assert_equal I18n.t("native_questions.create.no_recording"), flash[:alert]
    assert_not_requested :post, "https://abairt.com/api/questions"
  end

  test "says so when Abairt doesn't take it" do
    stub_request(:post, "https://abairt.com/api/questions").to_return(status: 403)

    with_abairt_token { post native_questions_path, params: { audio: recording } }

    assert_equal I18n.t("native_questions.create.not_sent"), flash[:alert]
    assert_empty @learner.native_questions
  end

  test "opening the page picks up answers and marks them heard" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    stub_request(:get, "https://abairt.com/api/questions/7")
      .to_return(status: 200, body: { id: 7, status: "answered", answer_audio_url: "https://abairt.test/a7" }.to_json)

    with_abairt_token { get native_questions_path }

    assert_select "audio[src=?]", "https://abairt.test/a7"
    assert_select ".chip", text: I18n.t("native_questions.index.new_answer")
    assert question.reload.answer_seen_at
  end

  test "an unreachable Abairt doesn't stop the page" do
    @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    stub_request(:get, "https://abairt.com/api/questions/7").to_timeout

    with_abairt_token { get native_questions_path }

    assert_response :success
    assert_select "p", text: I18n.t("native_questions.index.with_a_speaker")
  end

  test "the home screen says when there's an answer to hear" do
    @learner.native_questions.create!(abairt_question_id: 7, status: "answered", answer_audio_url: "https://abairt.test/a7")

    get root_path

    assert_select "a[href=?]", native_questions_path, text: /#{I18n.t("daily_path.answer_title", count: 1)}/
  end

  test "the lesson page links to asking about it" do
    with_abairt_token { get lesson_path(@lesson) }

    assert_select "a[href=?]", native_questions_path(lesson: @lesson.number)
  end
end
