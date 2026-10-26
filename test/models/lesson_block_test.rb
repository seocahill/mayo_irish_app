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

  test "other block types ignore the url" do
    assert @lesson.lesson_blocks.build(block_type: "text", url: "whatever").valid?
  end
end
