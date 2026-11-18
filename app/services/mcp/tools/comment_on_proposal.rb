module Mcp
  module Tools
    # Adds one comment to a proposal's discussion. Adds a row; changes nothing else.
    class CommentOnProposal < Base
      tool_name "comment_on_proposal"
      description "Add a comment to a proposal's discussion, word for word (max 2000 characters). " \
                  "Do not rewrite or correct it, and never guess Irish spelling. It does not change " \
                  "the proposal's status or any lesson."
      annotations(
        title: "Comment on proposal",
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: false
      )
      input_schema(
        properties: { id: { type: "integer", description: "Proposal id" },
                      text: { type: "string", maxLength: 2000, description: "The comment, in the person's own words" } },
        required: [ "id", "text" ]
      )

      def self.call(id:, text:, server_context:)
        proposal = CourseProposal.find_by(id: id)
        return error("No proposal with id #{id}") unless proposal
        author = server_context[:user]&.email_address.to_s.split("@").first.presence || "mcp"
        c = proposal.proposal_comments.build(author: author, body: text.to_s.strip)
        c.save ? json_response(id: c.id, proposal_id: proposal.id) : error(c.errors.full_messages.join(", "))
      end
    end
  end
end
