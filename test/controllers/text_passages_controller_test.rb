require "test_helper"

class TextPassagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin   = users(:admin)
    @user    = users(:two)
    @passage = text_passages(:one)
  end

  test "unauthenticated user is redirected to login" do
    get edit_text_passage_path(@passage)
    assert_redirected_to new_session_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(@user)
    get edit_text_passage_path(@passage)
    assert_redirected_to root_path
  end

  test "admin can edit a text passage" do
    sign_in_as(@admin)
    get edit_text_passage_path(@passage)
    assert_response :success
  end
end
