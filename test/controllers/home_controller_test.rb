require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors are sent to sign in" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "learners who have not onboarded are sent to onboarding" do
    sign_in_as(users(:newcomer))
    get root_path
    assert_redirected_to new_onboarding_path
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
