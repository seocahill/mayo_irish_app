module Mcp
  # Builds the MCP server exposing the resource tools. `user` is the admin who
  # authorized the connector; it's passed through as server context. There is
  # deliberately no delete tool — destructive operations stay in the admin UI.
  class Server
    TOOLS = [
      Tools::ListRecords,
      Tools::GetRecord,
      Tools::CreateRecord,
      Tools::UpdateRecord
    ].freeze

    def self.build(user)
      ::MCP::Server.new(
        name: "mayo-irish",
        title: "Gaeilge Mhaigh Eo Admin",
        version: "1.0.0",
        tools: TOOLS,
        server_context: { user: user }
      )
    end
  end
end
