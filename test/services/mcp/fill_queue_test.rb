require "test_helper"

class Mcp::FillQueueTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @lesson.update!(published: false)
  end

  def call(**args)
    res = Mcp::Tools::FillQueue.call(server_context: {}, **args)
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  def slot(spec, at:, lesson: @lesson, **attrs)
    lesson.lesson_slots.create!(slot_type: "example_sentences", spec: spec, created_by: "admin@example.com", created_at: at, **attrs)
  end

  test "lists open slots oldest first with the lesson, type, spec and who added it" do
    newer = slot("Weather words", at: 1.hour.ago, slot_type: "vocabulary")
    older = slot("Sentences for the conditional after dá", at: 2.days.ago)
    slot("Gone", at: 3.days.ago).remove!(by: "admin@example.com")

    res, data = call

    assert_not res.error?
    assert_equal 2, data["open"]
    assert_equal [ older.id, newer.id ], data["slots"].map { |s| s["id"] }
    first = data["slots"].first
    assert_equal [ "example_sentences", "Sentences for the conditional after dá", "admin" ],
                 first.values_at("type", "spec", "added_by")
    assert_equal({ "number" => @lesson.number, "title" => @lesson.title, "published" => false }, first["lesson"])
    assert_equal [ { "number" => @lesson.number, "title" => @lesson.title, "published" => false, "open" => 2 } ], data["by_lesson"]
    assert_not_includes res.content.first[:text], "Gone"
    assert_not_includes res.content.first[:text], "@example.com"
  end

  test "can keep to one lesson, counting only that lesson" do
    other = Lesson.create!(number: 950, title: "Another draft", position: 950, published: false)
    slot("Mine", at: 1.day.ago)
    slot("Theirs", at: 2.days.ago, lesson: other)

    _, data = call(lesson: @lesson.number)

    assert_equal [ "Mine" ], data["slots"].map { |s| s["spec"] }
    assert_equal 1, data["open"]
    assert_equal [ @lesson.number ], data["by_lesson"].map { |l| l["number"] }
  end

  test "a lesson with no open slots gives an empty list" do
    slot("Elsewhere", at: 1.day.ago, lesson: Lesson.create!(number: 951, title: "Other", position: 951, published: false))

    _, data = call(lesson: @lesson.number)

    assert_equal [ 0, [], [] ], data.values_at("open", "by_lesson", "slots")
  end

  test "an unknown lesson is an error" do
    res, = call(lesson: 99_999)

    assert res.error?
    assert_includes res.content.first[:text], "no lesson 99999"
  end

  test "the limit is kept between 1 and 25" do
    6.times { |i| slot("Slot #{i}", at: (10 - i).hours.ago) }

    assert_equal 5, call[1]["slots"].size
    assert_equal 1, call(limit: 0)[1]["slots"].size
    assert_equal 6, call(limit: 100)[1]["slots"].size
  end

  test "an empty queue says so plainly" do
    _, data = call

    assert_equal [ 0, [], [] ], data.values_at("open", "by_lesson", "slots")
  end

  test "changes nothing" do
    slot("Keep", at: 1.day.ago)

    assert_no_changes -> { LessonSlot.pluck(:status, :updated_at) } do
      call
    end
  end
end
