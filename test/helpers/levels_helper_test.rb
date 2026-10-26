require "test_helper"

class LevelsHelperTest < ActionView::TestCase
  test "level_classes returns full class strings for every level" do
    %i[eist foghlaim cleacht labhair].each do |level|
      assert_equal %i[border stripe text tint], level_classes(level).keys.sort
    end
    assert_equal "bg-foghlaim", level_classes(:foghlaim)[:stripe]
  end

  test "level_classes rejects unknown levels" do
    assert_raises(KeyError) { level_classes(:nonsense) }
  end

  test "field recordings are listening material and everything else is the course" do
    assert_equal :eist, lesson_level(Lesson.new(lesson_type: "dias_material"))
    assert_equal :foghlaim, lesson_level(Lesson.new(lesson_type: "curriculum"))
    assert_equal :foghlaim, lesson_level(Lesson.new(lesson_type: "thematic_vocab"))
  end
end
