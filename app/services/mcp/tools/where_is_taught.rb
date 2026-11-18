module Mcp
  module Tools
    # Read-only: where a word is taught, heard and practised in the course.
    class WhereIsTaught < Base
      LIMIT = 10

      tool_name "where_is_taught"
      description "Find where a word is taught, heard and reviewed. Give an Irish or English word; " \
                  "returns each matching vocabulary item with its lesson, whether it has a recording, " \
                  "how many Abairt listening clips and quiz questions use it, and which lessons " \
                  "use it in a phrase or exercise. Shows up to 10 matches (substring, case-insensitive for plain letters). Returns the course's own text only."
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
        items = VocabularyItem.includes(:lesson, :audio_attachment)
                              .where("irish LIKE :q ESCAPE '\\' OR english LIKE :q ESCAPE '\\'", q: like)
                              .order(:lesson_id, :position).limit(LIMIT).to_a
        ids = items.map(&:id)
        clips = ListeningClip.where(vocabulary_item_id: ids).group(:vocabulary_item_id).count
        quizzes = QuizQuestion.where(source_type: "VocabularyItem", source_id: ids).group(:source_id).count
        rows = items.map { |item| describe(item, clips[item.id].to_i, quizzes[item.id].to_i) }
        json_response(word: term, matches: rows, used_in_phrases: phrase_lessons(like), used_in_exercises: exercise_lessons(like))
      end

      def self.describe(item, clips, quizzes)
        {
          id: item.id, irish: item.irish, english: item.english,
          lesson: { number: item.lesson.number, title: item.lesson.title },
          has_recording: item.audio.attached? || item.audio_url.present?,
          listening_clips: clips,
          quiz_questions: quizzes
        }
      end
      private_class_method :describe

      def self.phrase_lessons(like)
        lessons_for(Phrase.where("irish LIKE :q ESCAPE '\\' OR english LIKE :q ESCAPE '\\'", q: like).distinct.pluck(:lesson_id))
      end
      private_class_method :phrase_lessons

      def self.exercise_lessons(like)
        lessons_for(Exercise.where("prompt LIKE :q ESCAPE '\\' OR answer LIKE :q ESCAPE '\\'", q: like).distinct.pluck(:lesson_id))
      end
      private_class_method :exercise_lessons

      def self.lessons_for(ids)
        Lesson.where(id: ids.uniq).order(:number).limit(LIMIT).map { |l| { number: l.number, title: l.title } }
      end
      private_class_method :lessons_for
    end
  end
end
