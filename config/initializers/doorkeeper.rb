# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  # Resolve the resource owner from our signed session cookie. Only an admin may
  # authorize the connector — anyone else is sent to sign in. This is the human
  # gate: the person clicking "Authorize" in the claude.ai OAuth flow must be a
  # signed-in admin of this app.
  resource_owner_authenticator do
    session_record = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    owner = session_record&.user if session_record&.user&.admin?
    if owner
      owner
    else
      session[:return_to_after_authenticating] = request.fullpath
      redirect_to(new_session_path)
      nil
    end
  end

  # --- Settings for the claude.ai MCP connector (OAuth 2.1 + PKCE) ---
  # Claude registers a public client and always sends an S256 PKCE challenge.
  grant_flows %w[authorization_code]
  force_pkce
  pkce_code_challenge_methods %w[S256]

  default_scopes "mcp:access"
  enforce_configured_scopes

  access_token_expires_in 2.hours
  use_refresh_token
end
