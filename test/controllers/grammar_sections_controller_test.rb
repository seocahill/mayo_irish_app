require "test_helper"

class GrammarSectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin   = users(:admin)
    @user    = users(:two)
    @section = grammar_sections(:one)
  end

  test "unauthenticated user is redirected to login" do
    get edit_grammar_section_path(@section)
    assert_redirected_to new_session_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(@user)
    get edit_grammar_section_path(@section)
    assert_redirected_to root_path
  end

  test "admin can edit a grammar section" do
    sign_in_as(@admin)
    get edit_grammar_section_path(@section)
    assert_response :success
  end
end
