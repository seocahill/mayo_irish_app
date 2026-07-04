require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two) # approved, non-admin
    SearchIndex.rebuild!
  end

  test "unauthenticated user is redirected to login" do
    get search_path(q: "house")
    assert_redirected_to new_session_path
  end

  test "authenticated user can open search with no query" do
    sign_in_as(@user)
    get search_path
    assert_response :success
  end

  test "authenticated user sees matching results" do
    sign_in_as(@user)
    get search_path(q: "house")
    assert_response :success
    assert_select "mark", minimum: 1 # highlighted term in a snippet
    assert_match "teach — house", @response.body
  end

  test "Irish search without fadas returns results" do
    lessons(:one).vocabulary_items.create!(irish: "fáilte", english: "welcome", position: 96)
    sign_in_as(@user)
    get search_path(q: "failte")
    assert_response :success
    assert_match "fáilte — welcome", @response.body
  end

  test "a query with no matches renders gracefully" do
    sign_in_as(@user)
    get search_path(q: "zzzznotfoundzzz")
    assert_response :success
    assert_match(/No results/i, @response.body)
  end
end
