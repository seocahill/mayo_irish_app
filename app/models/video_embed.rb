# Turns whatever an editor pastes (a YouTube or Vimeo link, an iframe embed
# code, or a link to a video file) into something safe to render.
#
#   VideoEmbed.parse("https://youtu.be/dQw4w9WgXcQ")  # => #<VideoEmbed iframe ...>
#   VideoEmbed.parse("<iframe src=...></iframe>")     # => same, if the host is allowed
#   VideoEmbed.parse("https://example.com/talk.mp4")  # => #<VideoEmbed file ...>
#   VideoEmbed.parse("https://example.com/page")      # => nil
#
# Embeds only come from hosts we trust, so a pasted iframe can't load arbitrary
# pages into a lesson. Files must be https.
class VideoEmbed
  FILE_EXTENSIONS = %w[.mp4 .webm .ogv .m4v .mov].freeze
  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com m.youtube.com youtube-nocookie.com www.youtube-nocookie.com].freeze
  VIMEO_HOSTS = %w[vimeo.com www.vimeo.com player.vimeo.com].freeze
  YOUTUBE_ID = /\A[\w-]{11}\z/

  attr_reader :kind, :src

  def self.parse(input)
    text = input.to_s.strip
    return if text.blank?

    url = text.include?("<") ? iframe_src(text) : text
    uri = parse_uri(url)
    return unless uri

    from_youtube(uri) || from_vimeo(uri) || from_file(uri)
  end

  def initialize(kind:, src:)
    @kind = kind
    @src = src
  end

  def iframe? = kind == :iframe
  def file? = kind == :file

  def self.iframe_src(markup)
    markup[/<iframe\b[^>]*\bsrc\s*=\s*["']([^"']+)["']/i, 1]
  end
  private_class_method :iframe_src

  def self.parse_uri(url)
    uri = URI.parse(url.to_s)
    uri if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
  private_class_method :parse_uri

  def self.from_youtube(uri)
    return unless uri.host.in?(YOUTUBE_HOSTS + %w[youtu.be])

    id = if uri.host == "youtu.be"
      uri.path.delete_prefix("/")
    elsif uri.path == "/watch"
      URI.decode_www_form(uri.query.to_s).to_h["v"]
    else
      uri.path[%r{\A/(?:embed|shorts|live|v)/([^/?]+)}, 1]
    end
    new(kind: :iframe, src: "https://www.youtube-nocookie.com/embed/#{id}") if id.to_s.match?(YOUTUBE_ID)
  end
  private_class_method :from_youtube

  def self.from_vimeo(uri)
    return unless uri.host.in?(VIMEO_HOSTS)

    id = uri.path[%r{\A/(?:video/)?(\d+)}, 1]
    new(kind: :iframe, src: "https://player.vimeo.com/video/#{id}") if id
  end
  private_class_method :from_vimeo

  def self.from_file(uri)
    return unless uri.scheme == "https" && FILE_EXTENSIONS.include?(File.extname(uri.path).downcase)

    new(kind: :file, src: uri.to_s)
  end
  private_class_method :from_file
end
