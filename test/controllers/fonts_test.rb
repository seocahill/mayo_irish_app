require "test_helper"

# Fonts are served from our own domain: no learner request goes to Google.
class FontsTest < ActionDispatch::IntegrationTest
  test "the layout loads local fonts and nothing from Google" do
    get new_session_path

    assert_response :success
    assert_no_match(/fonts\.(googleapis|gstatic)\.com/, response.body)
    assert_select "link[rel=stylesheet][href^='/assets/fonts-']", 1
    assert_select "link[rel=preload][as=font][href*='figtree-latin']", 1
  end

  test "every font file the stylesheet names exists, and the three families cover fadas" do
    css = Rails.root.join("app/assets/stylesheets/fonts.css").read

    %w[Figtree DM\ Mono Young\ Serif].each { |family| assert_includes css, %(font-family: "#{family}") }
    assert_equal 8, css.scan(%r{url\("[\w-]+\.woff2"\)}).size
    css.scan(%r{url\("([\w-]+\.woff2)"\)}).flatten.each do |file|
      assert Rails.root.join("app/assets/fonts", file).exist?, "#{file} is missing"
    end
    assert_includes css, "U+0000-00FF" # Basic Latin and Latin-1: á é í ó ú
  end
end
