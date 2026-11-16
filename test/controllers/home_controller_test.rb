require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors are led to signing in and the guide, not registering" do
    get root_path

    assert_response :success
    assert_select "p", text: /Invite only/
    [ new_session_path, guide_path ].each do |path|
      assert_select "main a[href=?]", path
    end
    assert_select "main a[href=?]", new_registration_path, count: 0
  end

  test "learners who have not onboarded are sent to onboarding" do
    sign_in_as(users(:newcomer))
    get root_path
    assert_redirected_to new_onboarding_path
  end

  test "Today carries a hidden install card for the browser to reveal" do
    sign_in_as(users(:two))
    get root_path

    assert_select "section[data-controller=install][hidden]" do
      assert_select "[data-install-target=ios]"
      assert_select "[data-install-target=android]"
      assert_select "button[data-action='install#dismiss']"
    end
  end

  test "Today shows a time per step and trims the list to the minutes chosen" do
    sign_in_as(users(:two))
    get root_path

    assert_select "a[href=?]", root_path(minutes: 10)
    assert_select "span", text: /about \d+ minutes?/
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one))

    get root_path(minutes: 5)

    assert_select "a[aria-current=true]", text: "5 min"
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one)), count: 0
    assert_select "a[href=?]", lesson_path(lessons(:one))
    assert_select "a[href=?]", root_path, text: "Show everything"
  end

  test "an unknown minutes value is ignored" do
    sign_in_as(users(:two))
    [ "7", "0", "-5", "abc" ].each do |value|
      get root_path(minutes: value)

      assert_response :success
      assert_select "a[aria-current=true]", count: 0
    end
    get root_path(minutes: 7)

    assert_response :success
    assert_select "a[aria-current=true]", count: 0
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one))
  end

  test "shows today's items and the learner's place" do
    sign_in_as(users(:two))
    get root_path

    assert_response :success
    assert_select "h1", "Your day"
    assert_select "a[href=?]", lesson_path(lessons(:one))
    assert_select "a[href=?]", lesson_chat_path(lessons(:one))
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one))
    assert_match "Ballindine", response.body
    assert_match "East Mayo", response.body
    assert_select "a[href=?]", OnboardingsHelper::GAELTACHT_1926_URL
  end

  test "shows where the learner has got to, and what is next" do
    users(:two).listening_times.create!(abairt_recording_id: 1, seconds: 6 * 60)
    sign_in_as(users(:two))
    get root_path

    assert_select "li", text: /Listened for 5 minutes to Mayo speakers.*next: 15 minutes/m
    assert_select "li", text: /Your first words come from a lesson's quiz/
    assert_select "li", text: /No spoken conversation yet/
  end

  test "shows the review forecast once reviews are scheduled" do
    sign_in_as(users(:two))
    get root_path
    assert_select "p", text: /Tomorrow:/, count: 0

    QuizQuestion.sync_for(lessons(:one))
    QuizReview.create!(user: users(:two), quiz_question: QuizQuestion.first, box: 2, due_at: Time.current.tomorrow.noon)
    get root_path
    assert_select "p", text: /Tomorrow: 1/

    QuizReview.update_all(due_at: 4.days.from_now.noon)
    get root_path
    assert_select "p", text: /Tomorrow: 0 · This week: 1/

    QuizReview.update_all(due_at: 30.days.from_now)
    get root_path
    assert_select "p", text: /Tomorrow:/, count: 0
  end

  test "shows an empty state when there is nothing to do" do
    Lesson.update_all(published: false)
    sign_in_as(users(:two))
    get root_path

    assert_response :success
    assert_match "Nothing is due today", response.body
  end

  test "shows the minutes the learner has spoken" do
    user = users(:two)
    chat = user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
    4.times { chat.chat_messages.create!(role: "user", content: "spoken", spoken_seconds: 30) }
    sign_in_as(user)

    get root_path

    assert_match "minutes spoken", response.body
    assert_match "2 this week", response.body
  end
end
