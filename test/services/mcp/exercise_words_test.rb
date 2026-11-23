require "test_helper"

class Mcp::ExerciseWordsTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @exercise = exercises(:one)
    @exercise.update!(prompt: "Is the dog in the house?")
  end

  def call(**args)
    Mcp::Tools::ExerciseWords.call(server_context: {}, **args)
  end

  def data(**args) = JSON.parse(call(**args).content.first[:text])

  test "lists a lesson's exercises with the course words in each" do
    result = data(lesson: @lesson.number)

    assert_equal @lesson.number, result.dig("lesson", "number")
    exercise = result["exercises"].sole
    assert_equal "Is the dog in the house?", exercise["prompt"]
    assert_nil exercise["answer"]
    assert_equal "english", exercise["prompt_language"]
    assert_equal %w[madra teach], exercise["course_words"].map { |w| w["irish"] }
    assert exercise["course_words"].all? { |w| w.dig("lesson", "this_lesson") }
    assert_equal false, exercise["more_words"]
    assert_empty exercise["mayo_forms"]
  end

  test "one exercise, or only the unanswered ones, and Mayo forms pairs" do
    other = @lesson.exercises.create!(number: 2, position: 2, prompt: "Tá sé deacair.", answer: "Tá sé doiligh.")
    DialectSubstitution.create!(other_form: "deacair", mayo_form: "doiligh")

    one = data(lesson: @lesson.number, exercise: 2)["exercises"].sole
    assert_equal other.id, one["id"]
    assert_equal "Tá sé doiligh.", one["answer"]
    assert_equal "irish", one["prompt_language"]
    assert_equal [ { "other_form" => "deacair", "mayo_form" => "doiligh" } ], one["mayo_forms"]

    assert_equal [ @exercise.id ], data(lesson: @lesson.number, unanswered_only: true)["exercises"].map { |e| e["id"] }
  end

  test "an unknown lesson or exercise is an error, and nothing changes" do
    assert call(lesson: 999).error?
    assert call(lesson: @lesson.number, exercise: 99).error?
    assert_no_changes -> { [ Exercise.count, Exercise.maximum(:updated_at), VocabularyItem.count, DialectSubstitution.count ] } do
      call(lesson: @lesson.number)
    end
  end

  test "an answered exercise asked for with unanswered_only is an empty list, not an error" do
    @exercise.update!(answer: "An bhfuil an madra sa teach?")

    result = call(lesson: @lesson.number, exercise: @exercise.number, unanswered_only: true)

    assert_not result.error?
    assert_empty JSON.parse(result.content.first[:text])["exercises"]
  end

  test "this lesson's words come before an earlier lesson's, and more_words says when some are left out" do
    later = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    later.vocabulary_items.create!(irish: "madra rua", english: "fox", position: 1)
    (ExerciseWords::LIMIT).times { |i| later.vocabulary_items.create!(irish: "focal#{i}", english: "word#{i}", position: i + 2) }
    later.exercises.create!(number: 1, position: 1, prompt: "The fox and the dog: #{(0...ExerciseWords::LIMIT).map { |i| "word#{i}" }.join(' ')}")

    words = data(lesson: 2)["exercises"].sole
    assert_equal "madra rua", words["course_words"].first["irish"]
    assert_equal ExerciseWords::LIMIT, words["course_words"].size
    assert words["course_words"].first.dig("lesson", "this_lesson")
    assert words["more_words"]

    words = data(lesson: 2, exercise: 1)["exercises"].sole
    assert_not words["course_words"].find { |w| w["irish"] == "madra" }, "only the first #{ExerciseWords::LIMIT} are shown"
  end

  test "an earlier lesson's word is marked as not this lesson's" do
    later = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    later.exercises.create!(number: 1, position: 1, prompt: "Where is the dog?")

    word = data(lesson: 2)["exercises"].sole["course_words"].sole
    assert_equal "madra", word["irish"]
    assert_equal({ "number" => 1, "title" => @lesson.title, "this_lesson" => false }, word["lesson"])
  end

  test "a lesson with no exercises gives an empty list" do
    Lesson.create!(number: 3, title: "Lesson Three", position: 3)
    assert_empty data(lesson: 3)["exercises"]
  end
end
