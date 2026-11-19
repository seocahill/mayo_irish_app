module Mcp
  module Tools
    # Read-only: the designer's Connemara -> Mayo pairs and where the other form
    # still appears in the course. Proposals only; nothing is changed.
    class MayoForms < Base
      tool_name "mayo_forms"
      description "List the Mayo forms substitution pairs the designers have entered (a Connemara or standard " \
                  "form and the Mayo form to use instead, with sources), and for each pair the lessons where " \
                  "the other form still turns up. Read-only; returns the designers' own text only."
      annotations(
        title: "Mayo forms",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: {})

      def self.call(server_context:)
        pairs = DialectSubstitution.lessons_by_pair.map do |s, lessons|
          {
            id: s.id, other_form: s.other_form, mayo_form: s.mayo_form,
            other_source: s.other_source, mayo_source: s.mayo_source, note: s.note,
            still_in_lessons: lessons.map { |l| { number: l.number, title: l.title } }
          }
        end
        json_response(pairs: pairs)
      end
    end
  end
end
