module Mcp
  module Tools
    # Read-only: one proposal with its original words and discussion.
    class GetProposal < Base
      tool_name "get_proposal"
      description "Open one course proposal or idea by id: title, status, the original words " \
                  "(verbatim), the evidence behind it (sources, quotes, audio) and the discussion so far."
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
        proposal = CourseProposal.find_by(id: id)
        return error("No proposal with id #{id}") unless proposal
        json_response(
          id: proposal.id, kind: proposal.kind, status: proposal.status, origin: proposal.origin, title: proposal.title,
          rationale: proposal.rationale, raw_text: proposal.raw_text,
          evidence: proposal.proposal_evidence.map { |e| { id: e.id, source: e.source, quote: e.quote, audio_url: e.audio_url } },
          comments: proposal.proposal_comments.map { |c| { author: c.author, body: c.body, at: c.created_at.iso8601 } }
        )
      end
    end
  end
end
