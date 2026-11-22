require "test_helper"

class WeeksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    QuizQuestion.sync_for(lessons(:one))
  end

  test "signed-out visitors are sent to sign in" do
    get weeks_path

    assert_redirected_to new_session_path
  end

  test "shows the learner's own last eight weeks, this week first" do
    travel_to Time.zone.parse("2026-11-18 12:00") do
      question = QuizQuestion.first
      3.times { |n| @learner.review_logs.create!(quiz_question: question, prompt: "teach", correct: n < 2, box_before: 1, box_after: 1, answered_at: Time.current) }
      ListeningDay.add(@learner, 300, on: Date.new(2026, 11, 10))
      users(:one).review_logs.create!(quiz_question: question, prompt: "teach", correct: true, box_before: 1, box_after: 1, answered_at: 1.week.ago)
      ListeningDay.add(users(:one), 600, on: Date.new(2026, 11, 3))
      other_chat = users(:one).chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
      2.times { other_chat.chat_messages.create!(role: "user", content: "spoken", spoken_seconds: 30) }
      sign_in_as(@learner)

      get weeks_path

      assert_response :success
      assert_select "h1", "Your weeks"
      assert_select "ol > li", 8
      assert_select "ol > li:first-child h2", "This week"
      assert_select "ol > li:first-child", text: /review answers\s+3\s+2 right/
      assert_select "ol > li:nth-child(2) h2", /Week of/
      assert_select "ol > li:nth-child(2)", text: /minutes listened\s+5\b/
      assert_select "ol > li:nth-child(2)", text: /review answers\s+0\b/
      assert_select "ol > li:nth-child(3)", text: /A quiet week/
      assert_select "ol > li:first-child", text: /minutes spoken\s+0\b/
    end
  end

  test "Today links to Your weeks under So far" do
    sign_in_as(@learner)

    get root_path

    assert_select "section[aria-labelledby=progress-heading] a[href=?]", weeks_path, text: "Your weeks"
  end
end
