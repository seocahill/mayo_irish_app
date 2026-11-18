module Mcp
  module Tools
    # Stores an idea in the course proposals inbox in the speaker's own words.
    # Adds one row; never changes lessons or existing records.
    class CaptureIdea < Base
      tool_name "capture_idea"
      description "Save a course idea in the inbox, word for word. `text` is stored verbatim " \
                  "(max 2000 characters); do not rewrite, translate or correct it, and never guess " \
                  "Irish spelling: ask the person to type Irish terms. It does not change any lesson."
      annotations(
        title: "Capture idea",
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: false
      )
      input_schema(
        properties: { text: { type: "string", maxLength: 2000, description: "The idea, in the person's own words" } },
        required: [ "text" ]
      )

      def self.call(text:, server_context:)
        user = server_context[:user]
        origin = user&.email_address.to_s.split("@").first.presence || "mcp"
        proposal = CourseProposal.capture(text, origin: origin)
        if proposal.save
          json_response(id: proposal.id, title: proposal.title, status: proposal.status)
        else
          error(proposal.errors.full_messages.join(", "))
        end
      end
    end
  end
end
