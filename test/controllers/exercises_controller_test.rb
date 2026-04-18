require "test_helper"

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin    = users(:admin)
    @user     = users(:two)
    @exercise = exercises(:one)
  end

  test "unauthenticated user is redirected to login" do
    get edit_exercise_path(@exercise)
    assert_redirected_to new_session_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(@user)
    get edit_exercise_path(@exercise)
    assert_redirected_to root_path
  end

  test "admin can edit an exercise" do
    sign_in_as(@admin)
    get edit_exercise_path(@exercise)
    assert_response :success
  end
end
