require "test_helper"

class AbairS2sClientTest < ActiveSupport::TestCase
  URL = "https://abair.ie/api/s2s".freeze

  test "sends the messages and returns the reply's text" do
    stub = stub_request(:post, URL)
           .with(body: { messages: [ { role: "user", content: "hello" } ] }.to_json)
           .to_return(status: 200, body: { text: "the reply" }.to_json)

    assert_equal "the reply", AbairS2sClient.new.reply([ { role: "user", content: "hello" } ])
    assert_requested stub
  end

  test "errors, odd bodies and timeouts all raise its own error" do
    stub_request(:post, URL).to_return(status: 500, body: "oops")
    assert_raises(AbairS2sClient::Error) { AbairS2sClient.new.reply([]) }

    stub_request(:post, URL).to_return(status: 200, body: { other: "x" }.to_json)
    assert_raises(AbairS2sClient::Error) { AbairS2sClient.new.reply([]) }

    stub_request(:post, URL).to_timeout
    assert_raises(AbairS2sClient::Error) { AbairS2sClient.new.reply([]) }
  end
end
