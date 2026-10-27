require "test_helper"

class LessonBlockTest < ActiveSupport::TestCase
  setup { @lesson = lessons(:one) }

  test "a video block needs a link we can embed" do
    block = @lesson.lesson_blocks.build(block_type: "video", url: "https://example.com/page")

    assert_not block.valid?
    assert_includes block.errors[:url].first, "supported video"
  end

  test "a video block accepts youtube, vimeo and mp4 links" do
    [ "https://youtu.be/dQw4w9WgXcQ", "https://vimeo.com/123456789", "https://example.com/a.mp4" ].each do |url|
      assert @lesson.lesson_blocks.build(block_type: "video", url: url).valid?, "#{url} should be valid"
    end
  end

  test "a video block can be created empty and filled in later" do
    assert @lesson.lesson_blocks.build(block_type: "video").valid?
  end

  test "an embed block shows only Abairt pages" do
    assert @lesson.lesson_blocks.build(block_type: "embed", url: "https://abairt.com/1926?embed").valid?

    [ "https://example.com/1926", "http://abairt.com/1926", "javascript:alert(1)", "not a url" ].each do |url|
      block = @lesson.lesson_blocks.build(block_type: "embed", url: url)

      assert_not block.valid?, "#{url} should be refused"
      assert_includes block.errors[:url].first, "Abairt"
    end
  end

  test "an embed block knows where its page's messages come from" do
    assert_equal "https://abairt.com", @lesson.lesson_blocks.build(block_type: "embed", url: "https://abairt.com/1926?embed").embed_origin
  end

  test "other block types ignore the url" do
    assert @lesson.lesson_blocks.build(block_type: "text", url: "whatever").valid?
  end
end
