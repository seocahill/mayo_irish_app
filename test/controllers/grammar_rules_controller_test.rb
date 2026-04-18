require "test_helper"

class GrammarRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user  = users(:two)
    @rule  = grammar_rules(:one)
  end

  test "unauthenticated user is redirected to login" do
    get edit_grammar_rule_path(@rule)
    assert_redirected_to new_session_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(@user)
    get edit_grammar_rule_path(@rule)
    assert_redirected_to root_path
  end

  test "admin can edit a grammar rule" do
    sign_in_as(@admin)
    get edit_grammar_rule_path(@rule)
    assert_response :success
  end
end
