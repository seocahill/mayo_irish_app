require "test_helper"

class WhatsNewControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @user.update_columns(created_at: Time.utc(2026, 1, 1), whats_new_seen_id: nil)
  end

  test "Today shows unread notes, newest first, with a way to dismiss them" do
    sign_in_as(@user)

    get root_path

    assert_response :success
    assert_select "#whats-new-heading"
    assert_select "section[aria-labelledby=whats-new-heading] li p.font-semibold", count: 3
    assert_select "section[aria-labelledby=whats-new-heading] li:first-child p.font-semibold", text: "The third note"
    assert_select "section[aria-labelledby=whats-new-heading] a[href='/review']"
    assert_select "section[aria-labelledby=whats-new-heading] form[action='#{whats_new_path}'] input[name=through][value='3']"
  end

  test "Got it hides what was shown and brings the learner back to Today" do
    sign_in_as(@user)

    patch whats_new_path, params: { through: 3 }

    assert_redirected_to root_path
    assert_equal 3, @user.reload.whats_new_seen_id
    get root_path
    assert_select "#whats-new-heading", false
  end

  test "a note added after they dismissed shows up on its own" do
    @user.update_columns(whats_new_seen_id: 2)
    sign_in_as(@user)

    get root_path

    assert_select "section[aria-labelledby=whats-new-heading] li p.font-semibold", count: 1, text: "The third note"
  end

  test "Got it only reads up to what the card carried" do
    sign_in_as(@user)

    patch whats_new_path, params: { through: 2 }

    assert_equal 2, @user.reload.whats_new_seen_id
    get root_path
    assert_select "section[aria-labelledby=whats-new-heading] li p.font-semibold", count: 1
  end

  test "a made-up id can't hide notes that don't exist yet" do
    sign_in_as(@user)

    patch whats_new_path, params: { through: 9999 }

    assert_equal 3, @user.reload.whats_new_seen_id
  end

  test "the page lists every note, marks the unread ones, and counts as reading them" do
    @user.update_columns(whats_new_seen_id: 1)
    sign_in_as(@user)

    get whats_new_path

    assert_response :success
    assert_select "ul > li", 3
    assert_select "ul > li", text: /The third note/
    assert_select "ul > li span", text: /New/, count: 2
    assert_equal 3, @user.reload.whats_new_seen_id
    get root_path
    assert_select "#whats-new-heading", false
  end

  test "the footer links to the page for signed-in learners" do
    sign_in_as(@user)

    get root_path

    assert_select "footer a[href='#{whats_new_path}']"
  end

  test "signed-out visitors are sent to sign in and see no link" do
    get whats_new_path
    assert_redirected_to new_session_path

    get root_path
    assert_select "footer a[href='#{whats_new_path}']", false
  end

  test "someone awaiting approval can't open it" do
    sign_in_as(users(:one))

    get whats_new_path

    assert_redirected_to pending_approval_path
  end
end
