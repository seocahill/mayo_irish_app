# Abairt (abairt.com), the corpus of Mayo Irish recordings and the way to its
# native speakers. Needs an API token in ABAIRT_API_TOKEN (an Abairt user's
# api_token). Not to be confused with ABAIR (AbairClient), the speech service.
#
#   AbairtClient.new.recordings_of("madra")           # => [ { "id" => 1, "word_or_phrase" => …, "audio_url" => …, "speaker" => {…} } ]
#   AbairtClient.new.ask(audio, asker_label: "philip") # => { "id" => 7, "status" => "waiting", … }
#   AbairtClient.new.question(7)                      # => { "status" => "answered", "answer_audio_url" => …, … }
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
    perform(Net::HTTP::Get.new(uri("/api/transcriptions", q: text, mayo: true, has_audio: true, per_page: limit), headers))
      .fetch("entries")
  rescue KeyError
    raise Error, "Abairt returned something unexpected"
  end

  # Sends a spoken question to a native speaker, on behalf of `asker_label`.
  def ask(audio, asker_label:)
    request = Net::HTTP::Post.new(uri("/api/questions"), headers)
    request.set_form([
      [ "audio", audio.read, { filename: audio.original_filename.presence || "question.webm", content_type: audio.content_type } ],
      [ "asker_label", asker_label ]
    ], "multipart/form-data")
    perform(request)
  end

  # A question asked earlier, with the answer's audio once a speaker has replied.
  def question(id) = perform(Net::HTTP::Get.new(uri("/api/questions/#{id.to_i}"), headers))

  private

  def uri(path, params = {})
    URI("#{@base_url}#{path}").tap { |u| u.query = URI.encode_www_form(params) if params.any? }
  end

  def headers = { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }

  def perform(request)
    raise Error, "ABAIRT_API_TOKEN is not set" if @token.blank?

    response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: request.uri.scheme == "https", open_timeout: 5, read_timeout: 30) do |http|
      http.request(request)
    end
    raise RateLimited, "Abairt's hourly limit is used up" if response.code == "429"
    raise Error, "Abairt returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "Abairt returned something unexpected"
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
    raise Error, "Abairt could not be reached: #{e.message}"
  end
end
