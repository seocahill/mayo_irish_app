require "test_helper"

class VideoEmbedTest < ActiveSupport::TestCase
  YOUTUBE_ID = "dQw4w9WgXcQ".freeze
  YOUTUBE_EMBED = "https://www.youtube-nocookie.com/embed/#{YOUTUBE_ID}".freeze

  test "youtube links in every common form become a privacy-friendly embed" do
    [
      "https://www.youtube.com/watch?v=#{YOUTUBE_ID}",
      "https://youtube.com/watch?v=#{YOUTUBE_ID}&t=42s",
      "https://youtu.be/#{YOUTUBE_ID}",
      "https://youtu.be/#{YOUTUBE_ID}?si=abc",
      "https://www.youtube.com/embed/#{YOUTUBE_ID}",
      "https://www.youtube.com/shorts/#{YOUTUBE_ID}",
      "https://m.youtube.com/watch?v=#{YOUTUBE_ID}"
    ].each do |link|
      embed = VideoEmbed.parse(link)

      assert embed&.iframe?, "expected #{link} to parse"
      assert_equal YOUTUBE_EMBED, embed.src
    end
  end

  test "vimeo links become the vimeo player" do
    [ "https://vimeo.com/123456789", "https://player.vimeo.com/video/123456789" ].each do |link|
      assert_equal "https://player.vimeo.com/video/123456789", VideoEmbed.parse(link).src
    end
  end

  test "a pasted iframe embed code is accepted when it points at an allowed host" do
    code = %(<iframe width="560" height="315" src="https://www.youtube.com/embed/#{YOUTUBE_ID}?si=x" frameborder="0" allowfullscreen></iframe>)

    assert_equal YOUTUBE_EMBED, VideoEmbed.parse(code).src
    assert_equal "https://player.vimeo.com/video/42", VideoEmbed.parse(%(<iframe src='https://player.vimeo.com/video/42'></iframe>)).src
  end

  test "an iframe pointing anywhere else is rejected" do
    assert_nil VideoEmbed.parse(%(<iframe src="https://evil.example.com/steal"></iframe>))
    assert_nil VideoEmbed.parse(%(<iframe src="javascript:alert(1)"></iframe>))
    assert_nil VideoEmbed.parse("<script>alert(1)</script>")
  end

  test "https links to video files play in a video element" do
    embed = VideoEmbed.parse("https://assets.abairt.com/darren-reagan-bofield.mp4")

    assert embed.file?
    assert_equal "https://assets.abairt.com/darren-reagan-bofield.mp4", embed.src
    assert VideoEmbed.parse("https://example.com/talk.webm?download=1").file?
  end

  test "plain http files and unknown pages are rejected" do
    assert_nil VideoEmbed.parse("http://example.com/talk.mp4")
    assert_nil VideoEmbed.parse("https://example.com/page")
    assert_nil VideoEmbed.parse("javascript:alert(1)")
    assert_nil VideoEmbed.parse("not a url")
  end

  test "youtube links without a valid video id are rejected" do
    assert_nil VideoEmbed.parse("https://www.youtube.com/watch?v=short")
    assert_nil VideoEmbed.parse("https://www.youtube.com/")
    assert_nil VideoEmbed.parse("https://www.youtube.com.evil.example/watch?v=#{YOUTUBE_ID}")
  end

  test "blank input is no video" do
    assert_nil VideoEmbed.parse(nil)
    assert_nil VideoEmbed.parse("   ")
  end
end
