module Mcp
  module Tools
    # Read-only: one proposal with its original words and discussion.
    class GetProposal < Base
      tool_name "get_proposal"
      description "Open one course proposal or idea by id: title, status, the original words " \
                  "(verbatim) and the discussion so far."
      annotations(
        title: "Get proposal",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: { id: { type: "integer", description: "Proposal id from list_ideas" } },
                   required: [ "id" ])

      def self.call(id:, server_context:)
        p = CourseProposal.find_by(id: id)
        return error("No proposal with id #{id}") unless p
        json_response(
          id: p.id, kind: p.kind, status: p.status, origin: p.origin, title: p.title,
          rationale: p.rationale, raw_text: p.raw_text,
          comments: p.proposal_comments.map { |c| { author: c.author, body: c.body, at: c.created_at.iso8601 } }
        )
      end
    end
  end
end
