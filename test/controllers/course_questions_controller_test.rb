require "test_helper"

class CourseQuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SearchIndex.rebuild!
    @lesson = lessons(:one)
    sign_in_as(users(:two))
  end

  def recording(bytes = "webm-bytes")
    Rack::Test::UploadedFile.new(StringIO.new(bytes), "audio/webm", original_filename: "speech.webm")
  end

  # The lesson finder asks first, then the answer.
  def stub_answer(answer: "Count people with the personal numbers.", lesson_numbers: [ 1 ])
    stub_openai_chats({ lesson_numbers: [ 1 ], keywords: [ "count" ] }, { answer: answer, lesson_numbers: lesson_numbers })
  end

  test "signed-out visitors are sent to sign in" do
    sign_out

    get new_course_question_path

    assert_redirected_to new_session_path
  end

  test "the page offers to type or record a question" do
    get new_course_question_path

    assert_response :success
    assert_select "form[action=?][data-turbo-frame=answer]", course_questions_path do
      assert_select "textarea[name=question]"
      assert_select "button[data-speech-input-target=micButton]"
    end
    assert_select "turbo-frame#answer"
  end

  test "every page links to it" do
    get root_path

    assert_select "header a[href=?]", new_course_question_path, text: I18n.t("layouts.application.ask")
  end

  test "a typed question is answered from the lessons, with links to them" do
    stub_answer

    post course_questions_path, params: { question: "How do I count people?" }

    assert_response :success
    assert_select "turbo-frame#answer" do
      assert_select "p", text: "How do I count people?"
      assert_select "p", text: "Count people with the personal numbers."
      assert_select "a[href=?]", lesson_path(@lesson), text: /Lesson 1/
      assert_select "p", text: I18n.t("course_questions.create.ai_notice")
    end
  end

  test "a recorded question is transcribed, shown as heard, and answered" do
    stub_openai_transcription("how do I count people")
    stub_answer

    post course_questions_path, params: { audio: recording }

    assert_response :success
    assert_select "turbo-frame#answer p", text: "how do I count people"
    assert_select "turbo-frame#answer a[href=?]", lesson_path(@lesson)
  end

  test "an unpublished lesson is never found for a learner" do
    @lesson.update!(published: false)
    stub_answer

    post course_questions_path, params: { question: "How do I count people?" }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: I18n.t("course_questions.create.no_answer")
  end

  test "asking nothing says so" do
    post course_questions_path, params: { question: "  " }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: I18n.t("course_questions.create.nothing_asked")
  end

  test "a recording that can't be transcribed asks the learner to try again" do
    stub_openai_transcription(status: 500)

    post course_questions_path, params: { audio: recording }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: I18n.t("course_questions.create.not_heard")
  end

  test "a recording that is too long is refused without being transcribed" do
    stub = stub_openai_transcription

    post course_questions_path, params: { audio: recording("x" * (SpeechTranscriber::MAX_AUDIO_BYTES + 1)) }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: I18n.t("course_questions.create.too_long")
    assert_not_requested stub
  end

  test "an answer that can't be got is reported" do
    stub_openai_chat("not json")

    post course_questions_path, params: { question: "How do I count people?" }

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: I18n.t("course_questions.create.no_answer")
  end
end
