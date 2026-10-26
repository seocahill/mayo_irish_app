# Speech calls to the ABAIR v4 API (abair.ie, the speech lab at Trinity College
# Dublin). Needs an API key in ABAIR_API_KEY.
#
#   AbairClient.new.synthesise("Dia duit")  # => WAV bytes
#   AbairClient.new.recognise(bytes)        # => "transcript"
#   AbairClient.new.voices                  # => what the key may use, for ABAIR_VOICE
class AbairClient
  class Error < StandardError; end
  class NotConfigured < Error; end
  class Unauthorized < Error; end
  class QuotaExceeded < Error; end

  BASE_URL = "https://api.abair.ie/v4".freeze

  # Bríd, a Mayo woman's voice, the only Mayo voice v4 has. `voices` lists the
  # others (Connemara, Kerry, Donegal…); ABAIR_VOICE overrides.
  DEFAULT_VOICE = "brid.piper".freeze

  # Limit of the recognition API.
  MAX_AUDIO_BYTES = 5.megabytes

  def self.configured? = ENV["ABAIR_API_KEY"].present?

  def self.voice = ENV.fetch("ABAIR_VOICE", DEFAULT_VOICE)

  def initialize(api_key: ENV["ABAIR_API_KEY"], voice: self.class.voice)
    @api_key = api_key
    @voice = voice
  end

  # v4's encoding enum is "wav" or "MP3", case and all.
  def synthesise(text)
    request = Net::HTTP::Post.new(uri("/synthesis", outputType: "JSON", audioEncoding: "wav"), "Content-Type" => "application/json")
    request.body = { input: text, voice: @voice, speed: 1.0 }.to_json

    Base64.decode64(perform(request).fetch("audioContent"))
  end

  # Accepts anything ffmpeg can decode, up to 30 seconds and 5 MB.
  def recognise(audio_bytes, filename: "speech.webm")
    request = Net::HTTP::Post.new(uri("/recognition/batch"))
    request.set_form([ [ "file", audio_bytes, { filename: filename, content_type: "application/octet-stream" } ] ], "multipart/form-data")

    perform(request).fetch("text", "")
  end

  def voices = perform(Net::HTTP::Get.new(uri("/synthesis/voices")))

  private

  def uri(path, params = {})
    URI("#{BASE_URL}#{path}").tap { |u| u.query = URI.encode_www_form(params) if params.any? }
  end

  def perform(request)
    raise NotConfigured, "ABAIR_API_KEY is not set" if @api_key.blank?

    request["abair-api-key"] = @api_key
    response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) do |http|
      http.request(request)
    end
    parse(response)
  rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
    raise Error, "ABAIR could not be reached: #{e.message}"
  end

  def parse(response)
    status = response.code.to_i
    return JSON.parse(response.body) if status.between?(200, 299)

    message = error_message(response)
    case status
    when 401, 403 then raise Unauthorized, message
    when 429 then raise QuotaExceeded, message
    else raise Error, message
    end
  rescue JSON::ParserError
    raise Error, "ABAIR returned something that isn't JSON"
  end

  def error_message(response)
    body = JSON.parse(response.body)
    "ABAIR #{response.code}: #{body["message"] || body["error"] || response.body}"
  rescue JSON::ParserError
    "ABAIR returned #{response.code}"
  end
end
