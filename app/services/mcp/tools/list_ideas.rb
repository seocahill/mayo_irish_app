module Mcp
  module Tools
    # Read-only: the open proposals and ideas waiting in the inbox.
    class ListIdeas < Base
      tool_name "list_ideas"
      description "List open course proposals and captured ideas (newest first, up to 20), " \
                  "with their status and the original words."
      annotations(
        title: "List ideas",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: {})

      def self.call(server_context:)
        rows = CourseProposal.pending.ordered.limit(20).map do |p|
          { id: p.id, kind: p.kind, status: p.status, origin: p.origin, title: p.title, raw_text: p.raw_text }
        end
        json_response(rows)
      end
    end
  end
end
