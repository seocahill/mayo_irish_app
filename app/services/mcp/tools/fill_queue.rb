module Mcp
  module Tools
    # Read-only: the open slots on draft lessons, oldest first. A slot is Irish
    # a draft still needs, described in English; it never holds Irish itself.
    class FillQueue < Base
      DEFAULT_LIMIT = 5
      MAX_LIMIT = 25

      tool_name "fill_queue"
      description "The open slots on draft lessons, oldest first: jobs for Irish a draft still needs, each described in English " \
                  "(for example \"3 to 5 example sentences for the conditional after dá, Erris preferred\"). For each: the lesson " \
                  "number and title, the slot type (example_sentences, vocabulary, phrases, dialogue, listening_clip or grammar_table), " \
                  "the spec, who added it and when. A lesson with open slots can't be published. Filling slots from here isn't built " \
                  "yet: the Irish is added in the lesson editor, then the slot is removed there. Never suggest Irish to fill a slot; " \
                  "ask the designer for it. Optionally only one lesson. Returns up to #{MAX_LIMIT} (default #{DEFAULT_LIMIT}), how many " \
                  "are open in all, and how many are open on each lesson. Changes nothing."
      annotations(
        title: "Fill queue",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: {
        lesson: { type: "integer", description: "Only slots on this lesson number" },
        limit: { type: "integer", minimum: 1, maximum: MAX_LIMIT, description: "How many to return (1 to #{MAX_LIMIT}, default #{DEFAULT_LIMIT})" }
      })

      def self.call(server_context:, lesson: nil, limit: nil)
        limit = (limit || DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
        scope = LessonSlot.open
        unless lesson.nil?
          found = Lesson.find_by(number: lesson)
          return error("There is no lesson #{lesson}.") unless found
          scope = scope.where(lesson: found)
        end
        slots = scope.oldest_first.includes(:lesson).limit(limit)

        json_response(
          open: scope.count,
          by_lesson: by_lesson(scope),
          slots: slots.map { |slot| describe(slot) }
        )
      end

      def self.by_lesson(scope)
        counts = scope.group(:lesson_id).count
        Lesson.where(id: counts.keys).order(:position, :number).map do |l|
          { number: l.number, title: l.title, published: l.published?, open: counts.fetch(l.id) }
        end
      end

      def self.describe(slot)
        {
          id: slot.id, type: slot.slot_type, spec: slot.spec,
          lesson: { number: slot.lesson.number, title: slot.lesson.title, published: slot.lesson.published? },
          added_by: slot.created_by, added_at: slot.created_at.iso8601
        }
      end
      private_class_method :by_lesson, :describe
    end
  end
end
