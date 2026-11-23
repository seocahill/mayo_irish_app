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
    assert_no_changes -> { Exercise.maximum(:updated_at) } do
      call(lesson: @lesson.number)
    end
  end
end
