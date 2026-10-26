require "test_helper"

class LessonContextTest < ActiveSupport::TestCase
  setup { @lesson = lessons(:one) }

  test "gives the vocabulary and grammar of the lesson" do
    context = LessonContext.new(@lesson).to_s

    assert_includes context, "VOCABULARY:"
    assert_includes context, "#{vocabulary_items(:dog).irish} (masc.) — #{vocabulary_items(:dog).english}"
    assert_includes context, "GRAMMAR RULES:"
    assert_includes context, grammar_rules(:one).title
  end

  test "includes the intro video's transcript when there is one" do
    assert_nil LessonContext.new(@lesson).intro

    @lesson.update!(intro_video_transcript: "what the teacher says")

    assert_includes LessonContext.new(@lesson).to_s, "what the teacher says"
  end

  test "the brief version keeps the vocabulary but only the grammar's titles" do
    @lesson.update!(intro_video_transcript: "t" * 3000)
    brief = LessonContext.new(@lesson).brief

    assert_includes brief, LessonContext.new(@lesson).vocabulary
    assert_includes brief, "1. #{grammar_rules(:one).title}"
    assert_not_includes brief, "GRAMMAR RULES:\n"
    assert_operator brief.length, :<, LessonContext.new(@lesson).to_s.length
    assert_includes brief, "t" * 1000
    assert_not_includes brief, "t" * 3000
  end

  test "leaves out what a lesson doesn't have" do
    empty = Lesson.create!(number: 9300, title: "Empty", position: 9300)

    assert_equal "", LessonContext.new(empty).to_s
  end
end
