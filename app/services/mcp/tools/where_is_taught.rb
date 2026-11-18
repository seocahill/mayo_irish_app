module Mcp
  module Tools
    # Read-only: where a word is taught, heard and practised in the course.
    class WhereIsTaught < Base
      LIMIT = 10

      tool_name "where_is_taught"
      description "Find where a word is taught, heard and reviewed. Give an Irish or English word; " \
                  "returns each matching vocabulary item with its lesson, whether it has a recording, " \
                  "how many Abairt listening clips and quiz questions use it, and which lessons " \
                  "use it in a phrase or exercise. Returns the course's own text only."
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
        term = word.to_s.strip
        return error("Give a word to look up") if term.length < 2
        like = "%#{VocabularyItem.sanitize_sql_like(term)}%"
        items = VocabularyItem.includes(:lesson)
                              .where("irish LIKE :q ESCAPE '\\' OR english LIKE :q ESCAPE '\\'", q: like)
                              .order(:lesson_id, :position).limit(LIMIT)
        rows = items.map { |item| describe(item) }
        json_response(word: term, matches: rows, used_in_phrases: phrase_lessons(like), used_in_exercises: exercise_lessons(like))
      end

      def self.describe(item)
        {
          id: item.id, irish: item.irish, english: item.english,
          lesson: { number: item.lesson.number, title: item.lesson.title },
          has_recording: item.audio_url.present?,
          listening_clips: ListeningClip.where(vocabulary_item_id: item.id).count,
          quiz_questions: QuizQuestion.where(source_type: "VocabularyItem", source_id: item.id).count
        }
      end
      private_class_method :describe

      def self.phrase_lessons(like)
        lessons_for(Phrase.where("irish LIKE :q ESCAPE '\\' OR english LIKE :q ESCAPE '\\'", q: like).pluck(:lesson_id))
      end
      private_class_method :phrase_lessons

      def self.exercise_lessons(like)
        lessons_for(Exercise.where("prompt LIKE :q ESCAPE '\\' OR answer LIKE :q ESCAPE '\\'", q: like).pluck(:lesson_id))
      end
      private_class_method :exercise_lessons

      def self.lessons_for(ids)
        Lesson.where(id: ids.uniq).order(:number).limit(LIMIT).map { |l| { number: l.number, title: l.title } }
      end
      private_class_method :lessons_for
    end
  end
end
