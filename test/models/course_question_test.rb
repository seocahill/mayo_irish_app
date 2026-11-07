require "test_helper"

class CourseQuestionTest < ActiveSupport::TestCase
  # Stands in for LessonFinder.
  Finder = Struct.new(:lessons) do
    def find(_question) = lessons
  end

  # Stands in for the OpenAI client: records the parameters and answers with `content`.
  class Openai
    attr_reader :requests

    def initialize(content) = (@content = content) && (@requests = [])

    def chat(parameters:)
      @requests << parameters
      raise @content if @content.is_a?(Exception)

      { "choices" => [ { "message" => { "content" => @content } } ] }
    end
  end

  setup { @lesson = lessons(:one) }

  def question(text = "how do I count people?", content: reply, found: [ @lesson ])
    @openai = Openai.new(content)
    CourseQuestion.new(text, lessons: Lesson.published, openai: @openai, finder: Finder.new(found))
  end

  def reply(answer: "Use the personal numbers (Lesson 1).", lesson_numbers: [ 1 ])
    { answer: answer, lesson_numbers: lesson_numbers }.to_json
  end

  test "answers with the text and the lessons it came from" do
    answer = question.answer

    assert_equal "Use the personal numbers (Lesson 1).", answer.text
    assert_equal [ @lesson ], answer.lessons
  end

  test "gives OpenAI the question and the full text of the lessons found" do
    question("  how do I\ncount people?  ").answer

    request = @openai.requests.first
    assert_equal "how do I count people?", request[:messages].last[:content]
    system = request[:messages].first[:content]
    assert_includes system, "=== LESSON 1: Lesson One ==="
    assert_includes system, "madra (masc.) — dog"
    assert_includes system, "Quote Irish only exactly as it is written"
  end

  test "only credits lessons that were found" do
    assert_empty question(content: reply(lesson_numbers: [ 42 ])).answer.lessons
  end

  test "refuses a question when no lesson could be found, without asking OpenAI" do
    asked = question(found: [])

    assert_raises(CourseQuestion::Error) { asked.answer }
    assert_empty @openai.requests
  end

  test "fails with an Error when the answer isn't usable" do
    assert_raises(CourseQuestion::Error) { question(content: "not json").answer }
    assert_raises(CourseQuestion::Error) { question(content: reply(answer: " ")).answer }
    assert_raises(CourseQuestion::Error) { question(content: Faraday::ConnectionFailed.new("down")).answer }
  end

  test "keeps a very long question to the limit" do
    question("a" * 2000).answer

    assert_equal CourseQuestion::MAX_CHARACTERS, @openai.requests.first[:messages].last[:content].size
  end
end
