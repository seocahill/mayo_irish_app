require "test_helper"

class AbairtClientTest < ActiveSupport::TestCase
  URL = %r{\Ahttps://abairt\.com/api/transcriptions}

  test "asks for confirmed Mayo recordings containing the text" do
    stub = stub_request(:get, URL)
           .with(query: hash_including("q" => "madra", "mayo" => "true", "has_audio" => "true"), headers: { "Authorization" => "Bearer t" })
           .to_return(status: 200, body: { entries: [ { id: 1 } ] }.to_json)

    assert_equal [ { "id" => 1 } ], AbairtClient.new(token: "t").recordings_of("madra")
    assert_requested stub
  end

  test "tells a used-up hourly limit apart from other errors" do
    stub_request(:get, URL).to_return(status: 429)
    assert_raises(AbairtClient::RateLimited) { AbairtClient.new(token: "t").recordings_of("x") }

    stub_request(:get, URL).to_return(status: 500)
    assert_raises(AbairtClient::Error) { AbairtClient.new(token: "t").recordings_of("x") }
  end

  test "needs a token" do
    assert_raises(AbairtClient::Error) { AbairtClient.new(token: nil).recordings_of("x") }
    assert_not_requested :get, URL
  end
end
