module SearchHelper
  # Render an FTS snippet, escaping the content but turning the highlight
  # sentinels (see Search::HIGHLIGHT_OPEN/CLOSE) into <mark> tags. Escaping
  # first means arbitrary content can never inject markup.
  def highlighted_snippet(snippet)
    return "" if snippet.blank?

    escaped = ERB::Util.html_escape(snippet)
    marked = escaped
      .gsub(Search::HIGHLIGHT_OPEN, '<mark class="bg-amber-100 text-stone-900 rounded px-0.5">')
      .gsub(Search::HIGHLIGHT_CLOSE, "</mark>")
    marked.html_safe
  end
end
