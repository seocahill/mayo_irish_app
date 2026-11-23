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

  test "questions from every learner are listed newest first" do
    older = users(:one).native_questions.create!(abairt_question_id: 1, status: "waiting", created_at: 2.days.ago)
    newer = @learner.native_questions.create!(abairt_question_id: 2, status: "waiting", created_at: 1.hour.ago)
    sign_in_as(users(:admin))

    get learner_questions_path

    ids = css_select("#learner-questions > li").map { |li| li["id"] }
    assert_equal [ newer, older ].map { |q| ActionView::RecordIdentifier.dom_id(q) }, ids
  end

  test "only a few unanswered questions are checked with Abairt, and it stops at the first failure" do
    5.times { |i| @learner.native_questions.create!(abairt_question_id: 100 + i, status: "sent", created_at: i.hours.ago) }
    stub_request(:get, %r{\Ahttps://abairt.com/api/questions/\d+\z}).to_return(status: 200, body: { status: "sent" }.to_json)
    sign_in_as(users(:admin))

    with_abairt_token { get learner_questions_path }

    assert_requested :get, %r{\Ahttps://abairt.com/api/questions/}, times: LearnerQuestionsController::REFRESH_AT_MOST

    WebMock.reset!
    stub_request(:get, %r{\Ahttps://abairt.com/api/questions/\d+\z}).to_timeout

    with_abairt_token { get learner_questions_path }

    assert_response :success
    assert_requested :get, %r{\Ahttps://abairt.com/api/questions/}, times: 1
  end

  test "without an Abairt token nothing is checked" do
    @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    sign_in_as(users(:admin))

    with_abairt_token(nil) { get learner_questions_path }

    assert_response :success
    assert_not_requested :get, %r{\Ahttps://abairt.com/}
  end

  test "a recording that isn't on https isn't played" do
    @learner.native_questions.create!(abairt_question_id: 7, status: "answered",
                                      audio_url: "javascript:alert(1)", answer_audio_url: "http://abairt.test/a7")
    sign_in_as(users(:admin))

    get learner_questions_path

    assert_select "#learner-questions audio", count: 0
  end

  test "learners cannot open it" do
    sign_in_as(@learner)

    get learner_questions_path

    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get learner_questions_path

    assert_redirected_to new_session_path
  end

  test "an admin saves a question as an idea and the card links to it" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "answered", answer_audio_url: "https://abairt.test/a7")
    sign_in_as(users(:admin))

    assert_difference -> { CourseProposal.count } => 1, -> { ProposalEvidence.count } => 1 do
      post learner_question_idea_path(question), params: { raw_text: "Learners mix up the two verbs to be" }
    end

    assert_redirected_to learner_questions_path(anchor: ActionView::RecordIdentifier.dom_id(question))
    idea = CourseProposal.last
    assert_equal [ "admin", "idea" ], [ idea.origin, idea.kind ]
    follow_redirect!
    assert_select "##{ActionView::RecordIdentifier.dom_id(question, :ideas)} a[href=?]", course_proposals_path(anchor: "proposal-#{idea.id}"),
                  text: "Learners mix up the two verbs to be"
    assert_select "summary", text: "Save another idea from it"
  end

  test "a blank idea isn't saved" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    sign_in_as(users(:admin))

    assert_no_difference -> { CourseProposal.count } do
      post learner_question_idea_path(question), params: { raw_text: " " }
    end

    assert_equal "Write the idea first.", flash[:alert]
  end

  test "learners cannot save ideas" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    sign_in_as(@learner)

    assert_no_difference -> { CourseProposal.count } do
      post learner_question_idea_path(question), params: { raw_text: "Sneaky" }
    end

    assert_redirected_to root_path
  end

  test "an idea that is too long says so" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")
    sign_in_as(users(:admin))

    post learner_question_idea_path(question), params: { raw_text: "a" * 2001 }

    assert_equal "That idea is too long. Keep it under 2,000 characters.", flash[:alert]
  end

  test "an unknown question is not found" do
    sign_in_as(users(:admin))

    post learner_question_idea_path(learner_question_id: 0), params: { raw_text: "Lost" }

    assert_response :not_found
  end

  test "signed-out visitors cannot save ideas" do
    question = @learner.native_questions.create!(abairt_question_id: 7, status: "sent")

    assert_no_difference -> { CourseProposal.count } do
      post learner_question_idea_path(question), params: { raw_text: "Sneaky" }
    end

    assert_redirected_to new_session_path
  end
end
