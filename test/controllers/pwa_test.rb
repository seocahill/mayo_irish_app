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
    assert_includes response.body, "caches.match"
  end

  test "the service worker precaches the offline page and the app shell" do
    get pwa_service_worker_path(format: :js)

    assert_includes response.body, '"/offline"'
    assert_match %r{"/assets/tailwind-[0-9a-f]+\.css"}, response.body
    assert_no_match(/<%/, response.body)
  end

  test "the offline page renders without signing in" do
    get offline_path

    assert_response :success
    assert_select "h1", text: "You're offline"
  end

  test "the offline page carries no navigation or CSRF token, even when signed in" do
    sign_in_as users(:one) if respond_to?(:sign_in_as, true)
    get offline_path

    assert_select "meta[name=csrf-token]", false
    assert_select "form", false
    assert_select "nav", false
  end

  test "the manifest has a separate maskable icon" do
    get pwa_manifest_path(format: :json)

    icons = response.parsed_body["icons"]
    maskable = icons.find { |i| i["purpose"] == "maskable" }
    assert_equal "/icon-maskable.png", maskable["src"]
    assert File.exist?(Rails.root.join("public/icon-maskable.png"))
    assert_not_equal icons.first["src"], maskable["src"]
  end

  test "the install prompt is captured at app level, not only where the card is" do
    js = File.read(Rails.root.join("app/javascript/application.js"))
    assert_includes js, "beforeinstallprompt"
    assert_includes js, "deferredInstallPrompt"
  end

  test "the layout registers the service worker" do
    assert_includes File.read(Rails.root.join("app/javascript/application.js")), 'register("/service-worker")'
  end

  test "the layout links the manifest and icons" do
    get new_session_path

    assert_select "link[rel=manifest][href=?]", pwa_manifest_path(format: :json)
    assert_select "link[rel=apple-touch-icon][href='/icon.png']"
  end
end
