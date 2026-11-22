module Mcp
  module Tools
    # Read-only: the Vocabulary gaps report, for the whole course or one lesson.
    class CourseGaps < Base
      LESSONS_PER_CHECK = 50
      EARLY_WORDS_LISTED = 50

      # Each lesson-level check: what it means, and the report method that lists
      # the lessons failing it. `words` on each lesson is the number of words the
      # check counts (all of them, or only those missing the thing).
      CHECKS = {
        no_words: [ "Lessons with no vocabulary at all", :empty_lessons ],
        no_recordings: [ "Lessons where no word has a speaker recording", :silent_lessons ],
        nothing_to_practise: [ "Lessons with words but no exercises and no phrases", :unpractised_lessons ],
        no_grammar_notes: [ "Lessons with words but no grammar rules", :ungrammared_lessons ],
        no_listening_clips: [ "Lessons where no word has a listed Abairt listening clip", :unlistened_lessons ],
        no_reading_text: [ "Lessons with words but no reading text", :unread_lessons ],
        recordings_without_speaker: [ "Lessons with recorded words that name no speaker (words = how many)", :uncredited_lessons ],
        words_without_source: [ "Lessons with words that have no source note (words = how many)", :unsourced_lessons ],
        not_reviewed: [ "Lessons with words that no editor has marked reviewed", :unreviewed_lessons ]
      }.freeze

      tool_name "course_gaps"
      description "What the course is missing, from the same report as the Vocabulary gaps page. With no lesson: " \
                  "each check (no words, no recordings, nothing to practise, no grammar notes, no listening clips, " \
                  "no reading text, recordings with no speaker, words with no source, not reviewed) with the lessons " \
                  "that fail it (up to #{LESSONS_PER_CHECK} each), how many words lack a genitive, plural or recording " \
                  "and in how many lessons, " \
                  "words not yet marked noun/verb/etc., repeated words, thin everyday themes, and words used before " \
                  "they're taught (a curriculum lesson teaches them but an earlier one's reading, phrases or exercises " \
                  "already use them; exact forms only, so mutated forms are missed; up to #{EARLY_WORDS_LISTED}). " \
                  "With a lesson number: the checks that lesson fails, its words missing a genitive, plural or " \
                  "recording, its words also taught in other lessons, and (for curriculum lessons only; otherwise both " \
                  "are empty) used_before_taught, the words it uses before a later lesson teaches them, and " \
                  "taught_after_used, the words it teaches that earlier lessons already used. Each word has its id. Drafts are included. Returns the course's " \
                  "own text only; changes nothing."
      annotations(
        title: "Course gaps",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: { lesson: { type: "integer", description: "A lesson number, to see only that lesson's gaps" } })

      def self.call(server_context:, lesson: nil)
        gaps = VocabularyGaps.new
        return json_response(course(gaps)) if lesson.nil?

        found = Lesson.find_by(number: lesson)
        return error("No lesson numbered #{lesson}") unless found

        json_response(one_lesson(gaps, found))
      end

      def self.course(gaps)
        checks = CHECKS.to_h do |key, (meaning, method)|
          entries = gaps.public_send(method).map { |entry| lesson_entry(entry) }
          [ key, { meaning: meaning, count: entries.size, lessons: entries.first(LESSONS_PER_CHECK) } ]
        end
        {
          checks: checks,
          words_missing: gaps.totals,
          lessons_with_words_missing: gaps.rows.size,
          words_not_classified: gaps.unclassified_count,
          repeated_words: gaps.repeats.size,
          thin_themes: gaps.thin_themes.map { |t| { theme: t.name, words: t.count } },
          used_before_taught: { count: gaps.early_words.size,
                                words: gaps.early_words.first(EARLY_WORDS_LISTED).map { |early| early_entry(early) } }
        }
      end

      def self.one_lesson(gaps, lesson)
        failing = CHECKS.filter_map do |key, (_, method)|
          key if gaps.public_send(method).any? { |entry| lesson_of(entry) == lesson }
        end
        row = gaps.rows.find { |r| r.lesson == lesson }
        words = (row&.items || []).map do |item|
          { id: item.id, irish: item.irish, english: item.english, missing: VocabularyGaps.missing_for(item) }
        end
        repeats = gaps.repeats.filter_map do |repeat|
          next unless repeat.items.any? { |item| item.lesson_id == lesson.id }

          { irish: repeat.irish, also_in_lessons: repeat.items.reject { |item| item.lesson_id == lesson.id }.map { |item| item.lesson.number } }
        end
        { lesson: { number: lesson.number, title: lesson.title, published: lesson.published? },
          fails: failing, words_missing: words, also_taught_elsewhere: repeats,
          used_before_taught: gaps.early_words.select { |early| early.used_in == lesson }.map { |early| early_entry(early) },
          taught_after_used: gaps.early_words.select { |early| early.taught_in == lesson }.map { |early| early_entry(early) } }
      end

      def self.early_entry(early)
        { id: early.item.id, irish: early.item.irish, english: early.item.english,
          first_used_in_lesson: early.used_in.number, taught_in_lesson: early.taught_in.number }
      end

      def self.lesson_entry(entry)
        lesson = lesson_of(entry)
        { number: lesson.number, title: lesson.title, words: entry.is_a?(Lesson) ? 0 : entry.count }
      end

      def self.lesson_of(entry) = entry.is_a?(Lesson) ? entry : entry.lesson

      private_class_method :course, :one_lesson, :lesson_entry, :lesson_of, :early_entry
    end
  end
end
