require "test_helper"

class Oauth::DiscoveryTest < ActionDispatch::IntegrationTest
  test "authorization server metadata is published" do
    get "/.well-known/oauth-authorization-server"
    assert_response :success
    meta = JSON.parse(@response.body)
    assert_equal %w[code], meta["response_types_supported"]
    assert_equal %w[S256], meta["code_challenge_methods_supported"]
    assert_includes meta["scopes_supported"], "mcp:access"
    assert meta["registration_endpoint"].present?
    assert meta["authorization_endpoint"].present?
    assert meta["token_endpoint"].present?
  end

  test "protected resource metadata points at the mcp endpoint" do
    get "/.well-known/oauth-protected-resource"
    assert_response :success
    meta = JSON.parse(@response.body)
    assert_match(/\/mcp\z/, meta["resource"])
    assert_includes meta["scopes_supported"], "mcp:access"
  end

  test "dynamic client registration provisions a public client" do
    assert_difference -> { Doorkeeper::Application.count }, 1 do
      post "/oauth/register", as: :json, params: {
        client_name: "Claude",
        redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ]
      }
    end
    assert_response :created
    body = JSON.parse(@response.body)
    assert body["client_id"].present?
    assert_equal "none", body["token_endpoint_auth_method"]
    assert_equal "mcp:access", body["scope"]

    application = Doorkeeper::Application.find_by(uid: body["client_id"])
    assert_not application.confidential?, "Claude registers a public (secret-less) client"
  end
end
