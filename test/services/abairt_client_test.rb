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

  test "asks a question, uploading the recording" do
    stub = stub_request(:post, "https://abairt.com/api/questions")
           .with(headers: { "Authorization" => "Bearer t", "Content-Type" => %r{\Amultipart/form-data} })
           .to_return(status: 201, body: { id: 7, status: "waiting" }.to_json)
    audio = Rack::Test::UploadedFile.new(StringIO.new("recording-bytes"), "audio/webm", original_filename: "question.webm")

    assert_equal({ "id" => 7, "status" => "waiting" }, AbairtClient.new(token: "t").ask(audio, asker_label: "philip, Mayo Irish course"))
    assert_requested stub
  end

  test "looks up a question" do
    stub_request(:get, "https://abairt.com/api/questions/7").to_return(status: 200, body: { id: 7, status: "answered" }.to_json)

    assert_equal "answered", AbairtClient.new(token: "t").question(7)["status"]
  end

  test "needs a token" do
    assert_raises(AbairtClient::Error) { AbairtClient.new(token: nil).recordings_of("x") }
    assert_not_requested :get, URL
  end
end
