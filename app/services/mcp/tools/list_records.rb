module Mcp
  module Tools
    class ListRecords < Base
      tool_name "list_records"
      description "List all records of a resource. Returns each record's fields as JSON, " \
                  "including rich-text fields rendered as HTML."
      annotations(
        title: "List records",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(
        properties: {
          resource: {
            type: "string",
            enum: Mcp::ResourceRegistry::RESOURCES,
            description: "Which resource collection to list"
          }
        },
        required: [ "resource" ]
      )

      def self.call(resource:, server_context:)
        return error("Unknown resource: #{resource}") unless registry.include?(resource)

        records = registry.model_for(resource).all.map { |record| serialize(record) }
        json_response(records)
      end
    end
  end
end
