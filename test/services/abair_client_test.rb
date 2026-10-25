require "test_helper"

class AbairClientTest < ActiveSupport::TestCase
  setup { @client = AbairClient.new(api_key: "k", voice: "anb.piper") }

  test "synthesise returns the decoded WAV and sends the key, voice and text" do
    stub = stub_request(:post, "https://api.abair.ie/v4/synthesis?audioEncoding=WAV&outputType=JSON")
           .with(headers: { "abair-api-key" => "k" }, body: hash_including("input" => "an bád", "voice" => "anb.piper"))
           .to_return(status: 200, body: { audioContent: Base64.strict_encode64("wav") }.to_json)

    assert_equal "wav", @client.synthesise("an bád")
    assert_requested stub
  end

  test "recognise returns the transcript" do
    stub_request(:post, "https://api.abair.ie/v4/recognition/batch")
      .with(headers: { "abair-api-key" => "k" })
      .to_return(status: 200, body: { text: "dia duit" }.to_json)

    assert_equal "dia duit", @client.recognise("audio-bytes")
  end

  test "voices lists what the key may use" do
    stub_request(:get, "https://api.abair.ie/v4/synthesis/voices").to_return(status: 200, body: [ { id: "anb.piper" } ].to_json)

    assert_equal [ { "id" => "anb.piper" } ], @client.voices
  end

  test "errors are told apart" do
    stub_request(:post, %r{/synthesis}).to_return(status: 401, body: { message: "bad key" }.to_json)
    error = assert_raises(AbairClient::Unauthorized) { @client.synthesise("x") }
    assert_match "bad key", error.message

    stub_request(:post, %r{/synthesis}).to_return(status: 429, body: { error: "balance used up" }.to_json)
    assert_raises(AbairClient::QuotaExceeded) { @client.synthesise("x") }

    stub_request(:post, %r{/synthesis}).to_return(status: 500, body: "oops")
    assert_raises(AbairClient::Error) { @client.synthesise("x") }
  end

  test "a missing key raises before any request is made" do
    assert_raises(AbairClient::NotConfigured) { AbairClient.new(api_key: nil).synthesise("x") }
    assert_not_requested :post, %r{abair\.ie}
  end

  test "configured? follows ABAIR_API_KEY" do
    with_abair_key("k") { assert AbairClient.configured? }
    with_abair_key("") { assert_not AbairClient.configured? }
  end
end
