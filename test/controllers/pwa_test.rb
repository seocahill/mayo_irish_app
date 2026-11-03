require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "the manifest describes the installable app without signing in" do
    get pwa_manifest_path(format: :json)

    assert_response :success
    manifest = response.parsed_body
    assert_equal "Gaeilge Mhaigh Eo", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/icon.png", manifest.dig("icons", 0, "src")
  end

  test "the service worker is served" do
    get pwa_service_worker_path(format: :js)

    assert_response :success
  end

  test "the layout links the manifest and icons" do
    get new_session_path

    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)
    assert_select "link[rel=apple-touch-icon][href='/icon.png']"
  end
end
