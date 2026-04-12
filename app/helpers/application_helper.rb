module ApplicationHelper
  # Parses a block of text containing numbered items (e.g. "1. foo 2. bar")
  # into [{number:, title:, body:}, ...].
  # Works whether items are on separate lines or run together inline.
  #
  # For single-line items (texts, exercises): title is nil, body has the content.
  # For multi-line items (grammar): the first line becomes the title, the rest the body.
  def video_embed_url(url)
    return url if url.blank?

    # YouTube: watch?v=ID or youtu.be/ID → embed/ID
    if url =~ /(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/
      "https://www.youtube.com/embed/#{$1}"
    # Vimeo: vimeo.com/ID → player.vimeo.com/video/ID
    elsif url =~ /vimeo\.com\/(\d+)/
      "https://player.vimeo.com/video/#{$1}"
    else
      url
    end
  end

  def parse_numbered_items(text)
    return [] if text.blank?

    chunks = text.split(/(?=\b\d+\.\s)/).map(&:strip).reject(&:empty?)

    chunks.filter_map do |chunk|
      if chunk =~ /\A(\d+)\.\s+(.*)\z/m
        number  = $1.to_i
        content = $2.strip
        lines   = content.split("\n", 2)
        if lines.size > 1 && lines.first == lines.first.upcase
          { number: number, title: lines.first.strip, body: lines.last.strip }
        else
          { number: number, title: nil, body: content }
        end
      else
        { number: nil, title: nil, body: chunk.strip }
      end
    end
  end
end
