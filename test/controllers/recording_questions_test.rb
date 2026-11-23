require "test_helper"

# Editors write questions to listen for on a whole recording; learners see
# them above the player with the answer behind a tap.
class RecordingQuestionsTest < ActionDispatch::IntegrationTest
  RECORDING = "https://abairt.com/api/voice_recordings/15"

  setup do
    ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                          audio_url: "https://clips.test/1", word_count: 3, abairt_recording_id: 15, abairt_recording_title: "A Story", starts_at: 12.0)
    stub_request(:get, RECORDING).to_return(status: 200, body: {
      id: 15, title: "A Story", audio_url: "https://abairt.test/story.mp3",
      lines: [ { irish: "one madra two", translation: "a phrase", start: 12.0, end: 13.5 } ]
    }.to_json)
  end

  test "an editor adds a question with its answer" do
    sign_in_as(users(:admin))

    assert_difference -> { RecordingQuestion.count } do
      post recording_questions_path(15), params: { recording_question: { question: "  Where was the dog? ", answer: "In the field" } }
    end

    question = RecordingQuestion.last
    assert_redirected_to recording_path(15, anchor: "questions")
    assert_equal [ 15, "Where was the dog?", "In the field", users(:admin) ], [ question.abairt_recording_id, question.question, question.answer, question.author ]
  end

  test "a question needs its answer" do
    sign_in_as(users(:admin))

    assert_no_difference -> { RecordingQuestion.count } do
      post recording_questions_path(15), params: { recording_question: { question: "Where was the dog?", answer: " " } }
    end
    assert_redirected_to recording_path(15, anchor: "questions")
    assert flash[:alert].present?
  end

  test "only recordings the course offers take questions" do
    sign_in_as(users(:admin))

    post recording_questions_path(99), params: { recording_question: { question: "Q", answer: "A" } }

    assert_response :not_found
    assert_empty RecordingQuestion.all
  end

  test "learners can't add or remove questions" do
    question = RecordingQuestion.create!(abairt_recording_id: 15, question: "Q", answer: "A")
    sign_in_as(users(:two))

    post recording_questions_path(15), params: { recording_question: { question: "Mine", answer: "A" } }
    assert_redirected_to root_path
    delete recording_question_path(question)
    assert_redirected_to root_path

    assert_equal [ question ], RecordingQuestion.all.to_a
  end

  test "an editor removes a question" do
    question = RecordingQuestion.create!(abairt_recording_id: 15, question: "Q", answer: "A")
    sign_in_as(users(:admin))

    delete recording_question_path(question)

    assert_redirected_to recording_path(15, anchor: "questions")
    assert_empty RecordingQuestion.all
  end

  test "a learner sees the questions above the player, in order, with each answer behind a tap" do
    RecordingQuestion.create!(abairt_recording_id: 15, question: "Who is speaking?", answer: "A woman from Erris")
    RecordingQuestion.create!(abairt_recording_id: 15, question: "Where was the dog?", answer: "In the field")
    RecordingQuestion.create!(abairt_recording_id: 16, question: "Another recording's", answer: "No")
    sign_in_as(users(:two))

    with_abairt_token { get recording_path(15) }

    assert_select "section#questions h2", text: I18n.t("recording_questions.section.heading")
    assert_select "[data-testid=recording-question]", count: 2
    assert_select "[data-testid=recording-question]:first-child p", text: "Who is speaking?"
    assert_select "[data-testid=recording-question] details summary", text: I18n.t("recording_questions.section.show_answer")
    assert_select "[data-testid=recording-question] details p", text: "In the field"
    assert_select "section#questions form", false
    assert_select "section#questions button", false
    assert_match(/id="questions".*data-controller="playback/m, response.body)
  end

  test "a learner sees no questions section when there are none" do
    sign_in_as(users(:two))

    with_abairt_token { get recording_path(15) }

    assert_select "section#questions", false
  end

  test "an editor sees the form, and a remove button on each question" do
    RecordingQuestion.create!(abairt_recording_id: 15, question: "Q", answer: "A")
    sign_in_as(users(:admin))

    with_abairt_token { get recording_path(15) }

    assert_select "section#questions form[action=?]", recording_questions_path(15) do
      assert_select "textarea[name='recording_question[question]'][required]"
      assert_select "textarea[name='recording_question[answer]'][required]"
    end
    assert_select "section#questions form[action=?] button", recording_question_path(RecordingQuestion.last), text: I18n.t("recording_questions.section.remove")
  end

  test "an editor's account can go without losing the questions they wrote" do
    editor = User.create!(email_address: "editor@example.com", password: "password123", admin: true, approved: true)
    question = RecordingQuestion.create!(abairt_recording_id: 15, question: "Q", answer: "A", author: editor)

    editor.destroy!

    assert_nil question.reload.author
  end
end
