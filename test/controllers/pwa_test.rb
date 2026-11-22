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
  test "the service worker keeps recent lessons network-first and clears them on sign in or out" do
    get pwa_service_worker_path(format: :js)
    js = response.body

    assert_includes js, 'const PAGES = "gmh-pages"'
    assert_includes js, "const MAX_PAGES = 10"
    # Lessons are fetched from the network first; the saved copy is only the fallback.
    assert_match(/async function lessonPage[\s\S]*await fetch\(request\)[\s\S]*catch/, js)
    assert_includes js, "!response.redirected"
    # Any POST to /session (sign in, or the sign-out form) forgets saved lessons.
    assert_includes js, 'url.pathname === "/session"'
    assert_includes js, "caches.delete(PAGES)"
    # Turbo frame loads and prefetches are not saved.
    assert_includes js, 'h.get("Turbo-Frame")'
    # Saved lessons and assets are not wiped by the shell cache cleanup on deploy.
    assert_includes js, 'key.startsWith("gmh-shell-")'
  end

  test "the lesson path pattern matches lesson pages only" do
    get pwa_service_worker_path(format: :js)
    pattern = response.body[%r{const LESSON_PATH = /(.+)/$}, 1]
    regex = Regexp.new(pattern.gsub("\\/", "/"))

    assert_match regex, "/lessons/12"
    assert_no_match regex, "/lessons/12/edit"
    assert_no_match regex, "/lessons"
    assert_no_match regex, "/lessons/new"
    assert_match regex, lesson_path(lessons(:one))
  end

  test "the offline page has a hidden place for saved lessons" do
    get offline_path

    assert_select "section#saved-lessons[hidden]"
    assert_select "h2", text: "Saved on this device"
    assert_select "a", text: "Try again"
  end

  test "lesson pages carry a hidden offline bar" do
    sign_in_as users(:two)
    get lesson_path(lessons(:one))

    assert_response :success
    assert_select "[data-controller=connection][hidden][role=status]", text: /You're offline/
    assert_select "h1", text: "Lesson One"
  end

end
