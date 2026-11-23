require "test_helper"

class LearnerQuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    @lesson = lessons(:one)
  end

  test "admins hear each question and its answer, with its lesson, and learners aren't named" do
    answered = @learner.native_questions.create!(abairt_question_id: 7, status: "answered", lesson: @lesson,
                                                 audio_url: "https://abairt.test/q7", answer_audio_url: "https://abairt.test/a7")
    waiting = @learner.native_questions.create!(abairt_question_id: 8, status: "waiting", audio_url: "https://abairt.test/q8")
    sign_in_as(users(:admin))

    get learner_questions_path

    assert_response :success
    assert_select "#learner-questions-count", text: "1 of 2 answered"
    assert_select "##{ActionView::RecordIdentifier.dom_id(answered)}" do
      assert_select "audio[src=?]", "https://abairt.test/q7"
      assert_select "audio[src=?]", "https://abairt.test/a7"
      assert_select "a[href=?]", lesson_path(@lesson)
      assert_select ".chip", text: "Answered"
    end
    assert_select "##{ActionView::RecordIdentifier.dom_id(waiting)}" do
      assert_select "audio", count: 1
      assert_select ".chip", text: "Waiting for a speaker"
      assert_select "span", text: /Not about a lesson/
    end
    assert_no_match @learner.email_address, response.body
  end

  test "opening it picks up new answers from Abairt without marking them heard for the learner" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    stub_request(:get, "https://abairt.com/api/questions/7")
      .to_return(status: 200, body: { id: 7, status: "answered", answer_audio_url: "https://abairt.test/a7" }.to_json)
    sign_in_as(users(:admin))

    with_abairt_token { get learner_questions_path }

    assert_select "audio[src=?]", "https://abairt.test/a7"
    assert question.reload.answered?
    assert_nil question.answer_seen_at
  end

  test "an unreachable Abairt doesn't stop the page" do
    @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    stub_request(:get, "https://abairt.com/api/questions/7").to_timeout
    sign_in_as(users(:admin))

    with_abairt_token { get learner_questions_path }

    assert_response :success
    assert_select ".chip", text: "With a speaker"
  end

  test "with no questions it says so" do
    sign_in_as(users(:admin))

    get learner_questions_path

    assert_select "#learner-questions-none"
    assert_select "#learner-questions", false
    assert_select "#learner-questions-count", false
  end

  test "it is linked from Course tools" do
    sign_in_as(users(:admin))

    get course_tools_path

    assert_select "a[href=?]", learner_questions_path
  end

  test "learners cannot open it" do
    sign_in_as(@learner)

    get learner_questions_path

    assert_redirected_to root_path
  end
end
