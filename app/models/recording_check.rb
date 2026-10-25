# Checks that a recording says what it should, by running it through ABAIR's
# recogniser. Some Abairt entries carry the wrong audio, so a suggestion is only
# marked as checked when the recogniser hears the word in it.
#
#   check = RecordingCheck.new("https://…/clip.mp3", word: "madra")
#   check.heard    # => what the recogniser made of it
#   check.passed?  # => whether it heard the word
class RecordingCheck
  MAX_REDIRECTS = 3

  attr_reader :heard

  def initialize(audio_url, word:, abair: AbairClient.new)
    @word = word
    @heard = abair.recognise(download(URI(audio_url)), filename: "clip.mp3")
  end

  def passed? = IrishText.includes?(@heard, @word)

  private

  def download(uri, redirects = 0)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 15) { |http| http.get(uri) }
    if response.is_a?(Net::HTTPRedirection) && redirects < MAX_REDIRECTS
      download(URI.join(uri, response["location"]), redirects + 1)
    elsif response.is_a?(Net::HTTPSuccess) && response.body.bytesize <= AbairClient::MAX_AUDIO_BYTES
      response.body
    else
      raise AbairClient::Error, "The recording couldn't be fetched (#{response.code})"
    end
  end
end
