require "test_helper"

class LessonBlocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user  = users(:two)
    @block = lesson_blocks(:one)
  end

  test "unauthenticated user is redirected to login" do
    get edit_lesson_block_path(@block)
    assert_redirected_to new_session_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(@user)
    get edit_lesson_block_path(@block)
    assert_redirected_to root_path
  end

  test "admin can edit a block" do
    sign_in_as(@admin)
    get edit_lesson_block_path(@block)
    assert_response :success
  end
end
