require "webmock/minitest"

module OpenaiTestHelper
  CHAT_URL = "https://api.openai.com/v1/chat/completions".freeze

  # A chat completion whose content is `content`, a string or (for the comhrá's
  # structured replies) a hash sent as JSON.
  def stub_openai_chat(content = "a reply", status: 200)
    content = content.to_json unless content.is_a?(String)
    stub_request(:post, CHAT_URL).to_return(
      status: status,
      headers: { "Content-Type" => "application/json" },
      body: { choices: [ { message: { role: "assistant", content: content } } ] }.to_json
    )
  end

  def stub_conversation_reply(irish: "reply in irish", english: "the reply in english", note: nil, status: 200)
    stub_openai_chat({ irish: irish, english: english, note: note }, status: status)
  end
end

class ActiveSupport::TestCase
  include OpenaiTestHelper
end
