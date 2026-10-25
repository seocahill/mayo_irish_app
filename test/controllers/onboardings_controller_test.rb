require "test_helper"

class OnboardingsControllerTest < ActionDispatch::IntegrationTest
  test "requires sign in" do
    get new_onboarding_path
    assert_redirected_to new_session_path
  end

  test "shows the questions" do
    sign_in_as(users(:newcomer))
    get new_onboarding_path

    assert_response :success
    assert_select "h1", "Where are you from?"
    assert_select "input[name='user[place]']"
    assert_select "input[type=radio][name='user[dialect_region]']", User.dialect_regions.size
    assert_select "input[type=radio][name='user[door]']", User.doors.size
  end

  test "saves the answers and goes home" do
    user = users(:newcomer)
    sign_in_as(user)

    post onboarding_path, params: { user: { place: "Belmullet", dialect_region: "erris", door: "school_irish" } }

    assert_redirected_to root_path
    user.reload
    assert user.onboarded?
    assert_equal "Belmullet", user.place
    assert user.region_erris?
    assert user.door_school_irish?
  end

  test "re-renders with errors when answers are missing" do
    user = users(:newcomer)
    sign_in_as(user)

    post onboarding_path, params: { user: { place: "", dialect_region: "erris", door: "beginner" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_not user.reload.onboarded?
  end

  test "ignores attempts to set other attributes" do
    user = users(:newcomer)
    sign_in_as(user)

    post onboarding_path, params: { user: { place: "Ballina", dialect_region: "other", door: "beginner", admin: true } }

    assert_not user.reload.admin?
  end

  test "an onboarded learner can change their answers" do
    user = users(:two)
    sign_in_as(user)

    post onboarding_path, params: { user: { place: "Achill", dialect_region: "achill", door: "beginner" } }

    assert_redirected_to root_path
    assert_equal "Achill", user.reload.place
  end
end
