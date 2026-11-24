require "test_helper"

# Only the exercise handling is tested here: a re-parse must never lose the
# answers editors wrote, and never takes an answer from the model.
class LessonStructureParserTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:json) do
    def chat(parameters:) = { "choices" => [ { "message" => { "content" => json } } ] }
  end

  setup do
    @lesson = Lesson.create!(number: 900, title: "Parser test", position: 900)
    @lesson.update_column(:exercises, "1. The sun is shining.")
    @lesson.exercises.create!(number: 1, prompt: "Old prompt", position: 1)
  end

  def parse(exercises)
    parser = LessonStructureParser.allocate
    parser.instance_variable_set(:@lesson, @lesson)
    parser.instance_variable_set(:@client, FakeClient.new({ "exercises" => exercises }.to_json))
    capture_io { parser.parse }
  end

  test "a re-parse replaces exercises nobody has answered, without taking an answer from the model" do
    parse([ { "number" => 1, "prompt" => "The sun is shining.", "answer" => "from the model", "position" => 1 } ])

    exercise = @lesson.exercises.reload.sole
    assert_equal "The sun is shining.", exercise.prompt
    assert_nil exercise.answer
  end

  test "a re-parse leaves a lesson's exercises alone once an editor has answered one" do
    @lesson.exercises.first.update!(answer: "An editor's answer")

    parse([ { "number" => 1, "prompt" => "The sun is shining.", "position" => 1 } ])

    exercise = @lesson.exercises.reload.sole
    assert_equal "Old prompt", exercise.prompt
    assert_equal "An editor's answer", exercise.answer
  end

  test "a re-parse leaves exercises alone once learners have reviewed one, even with its answer removed" do
    exercise = @lesson.exercises.first
    exercise.update!(answer: "An editor's answer")
    QuizQuestion.sync_exercises(@lesson)
    QuizReview.create!(user: users(:two), quiz_question: QuizQuestion.find_by!(source: exercise), due_at: 1.day.from_now)
    exercise.update!(answer: "")

    assert_no_difference -> { QuizReview.count } do
      parse([ { "number" => 1, "prompt" => "The sun is shining.", "position" => 1 } ])
    end
    assert_equal "Old prompt", @lesson.exercises.reload.sole.prompt
  end
end
