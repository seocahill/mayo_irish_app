module Mcp
  module Tools
    # Read-only: a lesson's exercises with the course words in each, the same
    # list the lesson editor shows under an exercise's answer box.
    class ExerciseWords < Base
      tool_name "exercise_words"
      description "For one lesson's exercises (or one exercise), the course's own words that turn up in each prompt: " \
                  "vocabulary from this lesson and the lessons before it, matched by English for an English prompt or by " \
                  "Irish for an Irish one (accents, case and a simple initial mutation aside), this lesson's first, up to " \
                  "#{::ExerciseWords::LIMIT} each, with the lesson that teaches each word; plus any Mayo forms pair whose " \
                  "other form is in an Irish prompt. Also each exercise's prompt and its answer if an editor has written one. " \
                  "Matching is a reminder, sometimes wrong (a word with two meanings). Never write or suggest an answer's " \
                  "Irish: the designer writes it, in the lesson editor. Changes nothing."
      annotations(
        title: "Exercise words",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: {
                     lesson: { type: "integer", description: "The lesson number" },
                     exercise: { type: "integer", description: "Only this exercise number in the lesson" },
                     unanswered_only: { type: "boolean", description: "Only exercises with no answer yet (default false)" }
                   },
                   required: [ "lesson" ])

      def self.call(lesson:, server_context:, exercise: nil, unanswered_only: false)
        found = Lesson.find_by(number: lesson)
        return error("There is no lesson #{lesson}.") unless found

        exercises = found.exercises.order(:position, :number)
        exercises = exercises.where(number: exercise) unless exercise.nil?
        exercises = exercises.where.not(id: Exercise.answered) if unanswered_only
        return error("Lesson #{lesson} has no exercise #{exercise}.") if exercise && exercises.none?

        json_response(lesson: { number: found.number, title: found.title },
                      exercises: exercises.map { |e| describe(e) })
      end

      def self.describe(exercise)
        words = ::ExerciseWords.new(exercise)
        {
          id: exercise.id, number: exercise.number, prompt: exercise.prompt, answer: exercise.answer,
          prompt_language: words.english? ? "english" : "irish",
          course_words: words.matches.map do |m|
            { irish: m.item.irish, english: m.item.english,
              lesson: { number: m.lesson.number, title: m.lesson.title, this_lesson: m.lesson.id == exercise.lesson_id } }
          end,
          more_words: words.more?,
          mayo_forms: words.substitutions.map { |s| { other_form: s.other_form, mayo_form: s.mayo_form } }
        }
      end
      private_class_method :describe
    end
  end
end
