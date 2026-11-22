module Mcp
  module Tools
    # Read-only: where a word is taught, heard and practised in the course.
    class WhereIsTaught < Base
      LIMIT = WordLocator::LIMIT

      tool_name "where_is_taught"
      description "Find where a word is taught, heard and reviewed. Give an Irish or English word; " \
                  "returns each matching vocabulary item with its lesson, whether it has a recording, " \
                  "how many Abairt listening clips and quiz questions use it, and which lessons " \
                  "use it in a phrase or exercise. Shows up to #{LIMIT} matches (substring, case-insensitive for plain letters). Returns the course's own text only."
      annotations(
        title: "Where is it taught",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: { word: { type: "string", description: "An Irish or English word, as typed" } },
                   required: [ "word" ])

      def self.call(word:, server_context:)
        locator = WordLocator.new(word)
        return error("Give a word to look up") unless locator.valid?

        json_response(word: locator.term, matches: locator.matches.map { |m| describe(m) },
                      used_in_phrases: locator.phrase_lessons.map { |l| lesson_json(l) },
                      used_in_exercises: locator.exercise_lessons.map { |l| lesson_json(l) })
      end

      def self.describe(match)
        item = match.item
        {
          id: item.id, irish: item.irish, english: item.english,
          lesson: lesson_json(item.lesson),
          has_recording: match.has_recording,
          listening_clips: match.listening_clips,
          quiz_questions: match.quiz_questions
        }
      end
      private_class_method :describe

      def self.lesson_json(lesson)
        { number: lesson.number, title: lesson.title }
      end
      private_class_method :lesson_json
    end
  end
end
