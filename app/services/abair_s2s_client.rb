# ABAIR's conversational AI: the step between recognition and synthesis on
# abair.ie/speech-to-speech. It isn't part of the public v4 API (ABAIR are happy
# for us to use it) and needs no key. It takes chat messages, a system message
# included, and returns the reply's text.
#
#   AbairS2sClient.new.reply([ { role: "user", content: "Hello" } ])  # => "…"
class AbairS2sClient
  class Error < StandardError; end

  URL = URI("https://abair.ie/api/s2s").freeze

  def reply(messages)
    response = Net::HTTP.start(URL.host, URL.port, use_ssl: true, open_timeout: 5, read_timeout: 20) do |http|
      http.post(URL.path, { messages: messages }.to_json, "Content-Type" => "application/json")
    end
    raise Error, "ABAIR s2s returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("text")
  rescue JSON::ParserError, KeyError
    raise Error, "ABAIR s2s returned something without a reply"
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
    raise Error, "ABAIR s2s could not be reached: #{e.message}"
  end
end
