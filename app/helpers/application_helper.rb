module ApplicationHelper
  # Parses a block of text containing numbered items (e.g. "1. foo 2. bar")
  # into [{number:, title:, body:}, ...].
  # Works whether items are on separate lines or run together inline.
  #
  # For single-line items (texts, exercises): title is nil, body has the content.
  # For multi-line items (grammar): the first line becomes the title, the rest the body.
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

  # Strings the Stimulus controllers need, rendered into the page by the layout
  # (see the `js` keys in config/locales).
  def js_translations
    { js: I18n.t("js") }
  end
end
