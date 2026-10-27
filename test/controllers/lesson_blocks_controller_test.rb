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

  test "learners see an Abairt page inside the lesson, sized by the page" do
    @block.update!(block_type: "embed", url: "https://abairt.com/1926?embed", caption: "The 1926 Gaeltacht")
    sign_in_as(@user)

    get lesson_path(@block.lesson)

    assert_select "iframe[src='https://abairt.com/1926?embed'][data-controller='embed-frame'][data-embed-frame-origin-value='https://abairt.com']"
    assert_select "figcaption", text: "The 1926 Gaeltacht"
  end

  test "editors can set an Abairt page's link" do
    sign_in_as(@admin)
    @block.update!(block_type: "embed")

    get edit_lesson_block_path(@block)

    assert_select "input[name='lesson_block[url]']"
  end
end
