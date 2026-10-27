# Marks the Irish in a piece of lesson HTML so the page can offer to read it
# aloud. Bold and italic text is the course's Irish unless it's plainly English
# (a heading, say); a table cell only counts if it's plainly Irish, since tables
# mix Irish, English and phonetics. Each piece gets lang="ga" and, in
# data-speak, the words to read: without phonetics, section references or an
# English gloss after a dash.
class SpeakableIrish
  # Letters only found in the course's phonetic transcriptions.
  PHONETIC = /[əɴɣçʃːʲɑɪɛɔʊŋɾʒθðɟɲʎ]/

  def initialize(html, language: CourseLanguage.current)
    @html = html
    @language = language
  end

  def to_html
    fragment = Nokogiri::HTML5.fragment(@html)
    fragment.css("strong, em").each { |node| mark(node) { |text| @language.of(text) != :english } }
    fragment.css("td").each { |node| mark(node) { |text| @language.of(text) == :irish } }
    fragment.to_html
  end

  private

  def mark(node)
    return if node.at_css("[data-speak]") || node.ancestors("[data-speak]").any?

    text = words_to_read(node.text)
    return unless readable?(text) && yield(text)

    node["lang"] = "ga"
    node["data-speak"] = text
  end

  def words_to_read(text)
    text.sub(/\s[—–]\s.*/m, " ")
      .gsub(%r{/[^/]*/}, " ")
      .gsub(/\([^)]*§[^)]*\)|§\s*[\d.]+/, " ")
      .squish
  end

  # Something to say, and not a fragment such as "-áil" or "an t-", or phonetics.
  def readable?(text)
    text.scan(/\p{L}/).size >= 2 && text.length <= Pronunciation::MAX_CHARACTERS &&
      !text.start_with?("-") && !text.end_with?("-") && !text.match?(PHONETIC)
  end
end
