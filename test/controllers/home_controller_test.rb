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
    assert_select "h1", "Mo lá"
    assert_select "a[href=?]", lesson_path(lessons(:one))
    assert_select "a[href=?]", lesson_chat_path(lessons(:one))
    assert_match "Ballindine", response.body
    assert_match "Oirthear Mhaigh Eo", response.body
    assert_select "a[href=?]", OnboardingsHelper::GAELTACHT_1926_URL
  end

  test "shows an empty state when there is nothing to do" do
    Lesson.update_all(published: false)
    sign_in_as(users(:two))
    get root_path

    assert_response :success
    assert_match "Nothing is due today", response.body
  end
end
