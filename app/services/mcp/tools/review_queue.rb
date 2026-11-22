module Mcp
  module Tools
    # Read-only: the next few open proposals to decide, ranked, two lines each.
    class ReviewQueue < Base
      DEFAULT_LIMIT = 5
      MAX_LIMIT = 5

      tool_name "review_queue"
      description "The next few open course proposals and ideas to decide, best first: people's own ideas " \
                  "before the designer agent's, then higher priority, then the one waiting longest. " \
                  "Each has its id, a title and a one-line summary, and how much evidence and discussion it has; " \
                  "open one with get_proposal. Returns up to #{MAX_LIMIT} (default #{DEFAULT_LIMIT}) and how many are open in all. " \
                  "Changes nothing."
      annotations(
        title: "Review queue",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(properties: { limit: { type: "integer", minimum: 1, maximum: MAX_LIMIT,
                                          description: "How many to return (1 to #{MAX_LIMIT}, default #{DEFAULT_LIMIT})" } })

      def self.call(server_context:, limit: nil)
        limit = (limit || DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
        proposals = CourseProposal.review_order.includes(:proposal_evidence, :proposal_comments).limit(limit)
        json_response(open_in_all: CourseProposal.pending.count, next: proposals.map { |p| describe(p) })
      end

      def self.describe(proposal)
        {
          id: proposal.id, title: proposal.title, summary: proposal.summary,
          kind: proposal.kind, status: proposal.status, origin: proposal.origin,
          from_a_person: proposal.origin != CourseProposal::AGENT_ORIGIN,
          priority: proposal.priority, waiting_since: proposal.created_at.iso8601,
          evidence: proposal.proposal_evidence.size, comments: proposal.proposal_comments.size
        }
      end
      private_class_method :describe
    end
  end
end
