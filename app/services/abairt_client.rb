# Abairt (abairt.com), the corpus of Mayo Irish recordings. Needs an API token
# in ABAIRT_API_TOKEN (an Abairt user's api_token). Not to be confused with
# ABAIR (AbairClient), the speech service.
#
#   AbairtClient.new.recordings_of("madra")  # => [ { "id" => 1, "word_or_phrase" => …, "audio_url" => …, "speaker" => {…} } ]
class AbairtClient
  class Error < StandardError; end
  class RateLimited < Error; end

  def self.configured? = ENV["ABAIRT_API_TOKEN"].present?

  def initialize(token: ENV["ABAIRT_API_TOKEN"], base_url: ENV.fetch("ABAIRT_URL", "https://abairt.com"))
    @token = token
    @base_url = base_url
  end

  # Confirmed entries by Mayo speakers, with audio, whose Irish contains `text`.
  def recordings_of(text, limit: 20)
    raise Error, "ABAIRT_API_TOKEN is not set" if @token.blank?

    uri = URI("#{@base_url}/api/transcriptions")
    uri.query = URI.encode_www_form(q: text, mayo: true, has_audio: true, per_page: limit)
    request = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{@token}", "Accept" => "application/json")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 15) { |http| http.request(request) }

    raise RateLimited, "Abairt's hourly limit is used up" if response.code == "429"
    raise Error, "Abairt returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("entries")
  rescue JSON::ParserError, KeyError
    raise Error, "Abairt returned something unexpected"
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
    raise Error, "Abairt could not be reached: #{e.message}"
  end
end
