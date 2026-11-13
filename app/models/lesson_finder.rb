# Finds the lessons most likely to answer a learner's question, which may be
# put in any words ("how do I count people past ten?"). Two searches are
# combined: OpenAI reads an outline of the lessons and picks the ones that
# cover the topic, and the global full-text search (Search) looks up the
# English keywords OpenAI picks out of the question.
#
#   LessonFinder.new(Lesson.published).find("how do I count past ten")  # => [Lesson, …]
class LessonFinder
  MODEL = "gpt-4o-mini".freeze
  MAX_LESSONS = 8
  MAX_KEYWORDS = 6

  INSTRUCTIONS = <<~PROMPT.freeze
    You help a learner of Mayo Irish find the right lessons in their course. Below is an outline
    of the course: each line is a lesson number, its title and the titles of its grammar rules.
    From the learner's question, pick every lesson that covers the topic, best first, not just the closest one (at most
    #{MAX_LESSONS}), and list up to #{MAX_KEYWORDS} short English keywords to look up in the
    lessons' vocabulary and grammar. Use only lesson numbers that appear in the outline.

    Respond ONLY with a JSON object with the keys "lesson_numbers" and "keywords".
  PROMPT

  RESPONSE_FORMAT = {
    type: "json_schema",
    json_schema: {
      name: "lessons",
      strict: true,
      schema: {
        type: "object",
        additionalProperties: false,
        required: %w[lesson_numbers keywords],
        properties: {
          lesson_numbers: { type: "array", items: { type: "integer" } },
          keywords: { type: "array", items: { type: "string" } }
        }
      }
    }
  }.freeze

  # lessons is the scope the learner may read, so unpublished lessons stay out.
  def initialize(lessons, openai: OpenaiClient.build)
    @lessons = lessons
    @openai = openai
  end

  def find(question)
    picked = pick(question)
    numbers = (picked[:lesson_numbers] + numbers_matching(picked[:keywords])).uniq
    by_number = readable.index_by(&:number)
    numbers.filter_map { |number| by_number[number] }.first(MAX_LESSONS)
  end

  private

  def readable
    @readable ||= @lessons.ordered.includes(:grammar_rules).to_a
  end

  def pick(question)
    response = @openai.chat(parameters: {
      model: MODEL,
      messages: [ { role: "system", content: "#{INSTRUCTIONS}\n#{outline}" }, { role: "user", content: question } ],
      response_format: RESPONSE_FORMAT,
      temperature: 0,
      max_tokens: 300
    })
    reply = JSON.parse(response.dig("choices", 0, "message", "content").to_s)
    { lesson_numbers: Array(reply["lesson_numbers"]), keywords: Array(reply["keywords"]).first(MAX_KEYWORDS) }
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.warn("[lesson finder] OpenAI picked no lessons: #{e.message}")
    { lesson_numbers: [], keywords: question.to_s.scan(/[[:word:]]{4,}/).first(MAX_KEYWORDS) }
  end

  def outline
    readable.map do |lesson|
      "#{lesson.number}. #{lesson.title}: #{lesson.grammar_rules.map(&:title).join('; ')}"
    end.join("\n")
  end

  # Lessons with the most keyword matches first.
  def numbers_matching(keywords)
    hits = keywords.flat_map { |keyword| Search.new(keyword).results.map(&:lesson_number) }
    hits.tally.sort_by { |_number, count| -count }.map(&:first)
  end
end
