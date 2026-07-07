require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @application = Doorkeeper::Application.create!(
      name: "Test MCP Client",
      redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "mcp:access",
      confidential: false
    )
    @token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @admin.id,
      application: @application,
      scopes: "mcp:access",
      expires_in: 2.hours
    )
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token.token}", "Content-Type" => "application/json" }
  end

  test "rejects requests without a token" do
    post mcp_path, params: rpc("tools/list").to_json, headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
    assert_match "invalid_token", @response.body
    assert_match(/Bearer resource_metadata=/, @response.headers["WWW-Authenticate"])
  end

  test "rejects a token without the mcp:access scope" do
    other = Doorkeeper::AccessToken.create!(resource_owner_id: @admin.id, application: @application, scopes: "", expires_in: 2.hours)
    post mcp_path, params: rpc("tools/list").to_json,
         headers: { "Authorization" => "Bearer #{other.token}", "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "lists tools with a valid token" do
    post mcp_path, params: rpc("tools/list").to_json, headers: auth_headers
    assert_response :success
    body = JSON.parse(@response.body)
    names = body.dig("result", "tools").map { |t| t["name"] }
    assert_equal %w[create_record get_record list_records update_record], names.sort
  end

  test "create_record makes a lesson as an unpublished draft" do
    post mcp_path, headers: auth_headers, params: rpc("tools/call", {
      name: "create_record",
      arguments: { resource: "lessons", attributes: { title: "Wrestling", number: 9100, position: 9100, published: true } }
    }).to_json
    assert_response :success

    lesson = Lesson.find_by(number: 9100)
    assert_not_nil lesson
    assert_not lesson.published?, "connector-created lessons must be drafts even if published:true is passed"
  end

  test "tools advertise annotations so the connector can auto-approve edits" do
    post mcp_path, params: rpc("tools/list").to_json, headers: auth_headers
    assert_response :success
    tools = JSON.parse(@response.body).dig("result", "tools").index_by { |t| t["name"] }

    assert_equal false, tools.dig("update_record", "annotations", "destructiveHint")
    assert_equal false, tools.dig("update_record", "annotations", "readOnlyHint")
    assert_equal true,  tools.dig("update_record", "annotations", "idempotentHint")
    assert_equal false, tools.dig("create_record", "annotations", "destructiveHint")
    assert_equal true,  tools.dig("get_record", "annotations", "readOnlyHint")
    assert_equal true,  tools.dig("list_records", "annotations", "readOnlyHint")
  end

  test "update_record edits an existing record" do
    post mcp_path, headers: auth_headers, params: rpc("tools/call", {
      name: "update_record",
      arguments: { resource: "lessons", id: lessons(:one).id, attributes: { title: "Renamed" } }
    }).to_json
    assert_response :success

    assert_equal "Renamed", lessons(:one).reload.title
  end

  test "create_record accepts phonetic and notes on phrases" do
    post mcp_path, headers: auth_headers, params: rpc("tools/call", {
      name: "create_record",
      arguments: { resource: "phrases", attributes: {
        lesson_id: lessons(:one).id, irish: "bean a chaointe",
        english: "keening woman", phonetic: "b′an ə xiɴt′ə", notes: "§523"
      } }
    }).to_json
    assert_response :success

    phrase = Phrase.find_by(irish: "bean a chaointe")
    assert_not_nil phrase
    assert_equal "b′an ə xiɴt′ə", phrase.phonetic
    assert_equal "§523", phrase.notes
  end

  test "GET is not allowed even with a token" do
    get mcp_path, headers: auth_headers
    assert_response :method_not_allowed
  end

  private

  def rpc(method, params = {})
    { jsonrpc: "2.0", id: 1, method: method, params: params }
  end
end
