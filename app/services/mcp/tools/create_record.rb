module Mcp
  module Tools
    class CreateRecord < Base
      tool_name "create_record"
      description "Create a record of a resource. `attributes` is an object of field values; " \
                  "unknown or non-writable fields are ignored. Rich-text fields (e.g. body, " \
                  "vocabulary_notes_content) accept HTML. New lessons are created unpublished " \
                  "(draft) and must be published by a human in the admin UI. Call get_record or " \
                  "list_records first to learn a resource's fields. Returns the created record " \
                  "or validation errors."
      # Adds new rows; never deletes or overwrites existing data. Not idempotent
      # (each call makes another record), but non-destructive, so the connector
      # need not gate it behind a manual "destructive action" confirmation.
      annotations(
        title: "Create record",
        read_only_hint: false,
        destructive_hint: false,
        idempotent_hint: false,
        open_world_hint: false
      )
      input_schema(
        properties: {
          resource: {
            type: "string",
            enum: Mcp::ResourceRegistry::RESOURCES,
            description: "Which resource to create"
          },
          attributes: { type: "object", description: "Field values for the new record" }
        },
        required: [ "resource", "attributes" ]
      )

      def self.call(resource:, attributes:, server_context:)
        return error("Unknown resource: #{resource}") unless registry.include?(resource)

        values = writable(resource, attributes)
        # Guardrail: connector-created lessons always start as drafts.
        values["published"] = false if resource.to_s == "lessons"

        record = registry.model_for(resource).new(values)
        if record.save
          json_response(serialize(record))
        else
          error(record.errors.full_messages.join(", "))
        end
      end
    end
  end
end
