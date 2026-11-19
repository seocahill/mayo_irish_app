module Mcp
  module Tools
    # Adds one piece of evidence to a proposal. Adds a row; changes nothing else.
    class AddProposalEvidence < Base
      tool_name "add_proposal_evidence"
      description "Attach one supporting item to a course proposal: its source (book and page, " \
                  "Abairt entry and speaker, or a URL), an optional verbatim quote copied exactly " \
                  "from that source, and an optional audio link. Never write, correct or guess " \
                  "Irish; only quote it from the source. It does not change the proposal's status " \
                  "or any lesson."
      annotations(
        title: "Add proposal evidence",
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: false
      )
      input_schema(
        properties: { id: { type: "integer", description: "Proposal id" },
                      source: { type: "string", maxLength: 500, description: "Provenance: book and page, Abairt entry and speaker, or URL" },
                      quote: { type: "string", maxLength: 2000, description: "Verbatim quote from the source, if any" },
                      audio_url: { type: "string", maxLength: 500, description: "http(s) link to audio, if any" } },
        required: [ "id", "source" ]
      )

      def self.call(id:, source:, quote: nil, audio_url: nil, server_context:)
        proposal = CourseProposal.find_by(id: id)
        return error("No proposal with id #{id}") unless proposal
        e = proposal.proposal_evidence.build(source: source.to_s.strip, quote: quote.presence, audio_url: audio_url.to_s.strip.presence)
        e.save ? json_response(id: e.id, proposal_id: proposal.id) : error(e.errors.full_messages.join(", "))
      end
    end
  end
end
