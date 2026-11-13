require "test_helper"

class LessonFinderTest < ActiveSupport::TestCase
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

  setup do
    SearchIndex.rebuild!
    @lesson = lessons(:one)
  end

  def finder(content, lessons: Lesson.published)
    @openai = Openai.new(content)
    LessonFinder.new(lessons, openai: @openai)
  end

  def picks(lesson_numbers: [], keywords: []) = { lesson_numbers: lesson_numbers, keywords: keywords }.to_json

  test "finds the lessons OpenAI picks from the outline" do
    assert_equal [ @lesson ], finder(picks(lesson_numbers: [ 1 ])).find("anything")
  end

  test "the outline OpenAI reads lists each lesson with its grammar rules" do
    finder(picks).find("anything")

    outline = @openai.requests.first[:messages].first[:content]
    assert_includes outline, "1. Lesson One: Grammar Rule One"
    assert_equal "anything", @openai.requests.first[:messages].last[:content]
  end

  test "adds lessons the keywords turn up in the full-text search" do
    assert_equal [ @lesson ], finder(picks(keywords: [ "house" ])).find("anything")
  end

  test "ignores lesson numbers that aren't in the course" do
    assert_empty finder(picks(lesson_numbers: [ 999 ])).find("anything")
  end

  test "keeps to the lessons it was given" do
    assert_empty finder(picks(lesson_numbers: [ 1 ], keywords: [ "house" ]), lessons: Lesson.none).find("anything")
  end

  test "never offers more than the most lessons" do
    lessons = (2..10).map { |n| Lesson.create!(number: n, title: "Lesson #{n}", position: n) }
    numbers = [ 1 ] + lessons.map(&:number)

    assert_equal LessonFinder::MAX_LESSONS, finder(picks(lesson_numbers: numbers)).find("anything").size
  end

  test "falls back to searching the question's own words when OpenAI can't be reached" do
    assert_equal [ @lesson ], finder(Faraday::ConnectionFailed.new("down")).find("a house please")
  end
end
