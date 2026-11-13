# A learner's question about the course in plain English, answered from the
# lessons themselves. LessonFinder picks the relevant lessons, and OpenAI
# answers from their full text (LessonContext), pointing to the lessons it
# used. Nothing here is saved.
#
# Like the tutor chat, the answer may quote Irish only as the lessons write it.
# This never composes Irish of its own.
#
#   answer = CourseQuestion.new("how do I count people past ten?", lessons: Lesson.published).answer
#   answer.text     # => "Past ten, people are counted with …"
#   answer.lessons  # => [Lesson, …]
class CourseQuestion
  class Error < StandardError; end

  Answer = Struct.new(:text, :lessons)

  MODEL = "gpt-4o".freeze
  MAX_CHARACTERS = 500

  INSTRUCTIONS = <<~PROMPT.freeze
    You answer a learner's questions about Mayo Irish (Gaeilge Chonnacht) using only the lesson
    material below, which comes from their course.

    - Answer in English, clearly and briefly, the way a good teacher would at the kitchen table.
    - Quote Irish only exactly as it is written in the lessons below. Never compose, translate or
      correct Irish yourself, and never fill a gap with Irish from your own knowledge.
    - If the lessons do not answer the question, or only partly, say so plainly, then say what they
      do cover. Don't guess.
    - Say which lesson each point comes from, as "Lesson 12".
    - "lesson_numbers": the numbers of the lessons your answer drew on.

    Respond ONLY with a JSON object with the keys "answer" and "lesson_numbers".
  PROMPT

  RESPONSE_FORMAT = {
    type: "json_schema",
    json_schema: {
      name: "answer",
      strict: true,
      schema: {
        type: "object",
        additionalProperties: false,
        required: %w[answer lesson_numbers],
        properties: {
          answer: { type: "string" },
          lesson_numbers: { type: "array", items: { type: "integer" } }
        }
      }
    }
  }.freeze

  attr_reader :text

  # lessons is the scope the learner may read.
  def initialize(text, lessons:, openai: OpenaiClient.build, finder: LessonFinder.new(lessons, openai: openai))
    @text = text.to_s.squish.first(MAX_CHARACTERS)
    @openai = openai
    @finder = finder
  end

  def answer
    lessons = @finder.find(text)
    raise Error, "No lessons to answer from" if lessons.empty?

    reply = ask(lessons)
    cited = lessons.select { |lesson| reply["lesson_numbers"].to_a.include?(lesson.number) }
    Answer.new(reply.fetch("answer").to_s.strip.presence || raise(Error, "The model gave no answer"), cited)
  rescue JSON::ParserError, KeyError
    raise Error, "The model's answer wasn't usable"
  rescue Faraday::Error => e
    raise Error, "The question could not be answered: #{e.message}"
  end

  private

  def ask(lessons)
    response = @openai.chat(parameters: {
      model: MODEL,
      messages: [ { role: "system", content: system_prompt(lessons) }, { role: "user", content: text } ],
      response_format: RESPONSE_FORMAT,
      temperature: 0.2,
      max_tokens: 800
    })
    JSON.parse(response.dig("choices", 0, "message", "content").to_s)
  end

  def system_prompt(lessons)
    material = lessons.map { |lesson| "=== LESSON #{lesson.number}: #{lesson.title} ===\n#{LessonContext.new(lesson)}" }
    [ INSTRUCTIONS, *material ].join("\n\n")
  end
end
