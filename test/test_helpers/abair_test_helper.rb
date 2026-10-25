require "webmock/minitest"

module AbairTestHelper
  def stub_abair_synthesis(audio: "RIFFwav-bytes", status: 200)
    stub_request(:post, %r{\Ahttps://api\.abair\.ie/v4/synthesis})
      .to_return(status: status, body: { audioContent: Base64.strict_encode64(audio) }.to_json)
  end

  def with_abair_key(key = "test-key")
    previous = ENV["ABAIR_API_KEY"]
    ENV["ABAIR_API_KEY"] = key
    yield
  ensure
    ENV["ABAIR_API_KEY"] = previous
  end
end

class ActiveSupport::TestCase
  include AbairTestHelper
end
