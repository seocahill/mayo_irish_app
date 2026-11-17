# Looks up what Mayo speakers actually said, for a noun missing its plural or
# genitive: Abairt sentences containing a word that begins like the singular.
# Nothing here derives or writes Irish; every form offered is a word taken from
# an existing Abairt entry, for an editor to accept, and the entry is its source.
#
#   FormSuggester.new(item).call  # => [ #<data Candidate entry_id=…, irish="…", forms=["capaill"], …> ]
class FormSuggester
  Candidate = Data.define(:entry_id, :irish, :english, :audio_url, :speaker, :dialect, :confirmed, :forms, :places)

  def initialize(item, abairt: AbairtClient.new)
    @item = item
    @abairt = abairt
  end

  def call
    entries = Rails.cache.fetch([ "form-suggestions", @item.irish ], expires_in: 1.day) { @abairt.recordings_of(stem, limit: 30) }
    build(entries)
  end

  # Nouns only change at the end, so look up the start of the word.
  def stem = singular[0, prefix_length]

  private

  ARTICLES = %w[an na].freeze

  def singular = (IrishText.words(@item.irish) - ARTICLES).first.to_s

  def prefix_length = [ singular.length - 2, 3 ].max

  def related?(word)
    word != singular && word.length > 2 && word.start_with?(singular[0, prefix_length])
  end

  # The words as spoken and written (accents kept), lower-cased, that begin
  # like the singular; the comparison ignores accents but the form does not.
  def forms_in(text)
    text.to_s.scan(/[\p{L}'’]+/).map(&:downcase).select { |w| related?(IrishText.words(w).first.to_s) }.uniq
  end

  def build(entries)
    usable = entries.select { |e| e["audio_url"].present? && e["word_or_phrase"].present? }
    speakers = Hash.new { |h, k| h[k] = Set.new }
    usable.each do |e|
      forms_in(e["word_or_phrase"]).each { |w| speakers[IrishText.words(w).first] << e.dig("speaker", "name") }
    end

    candidates = usable.filter_map do |e|
      forms = forms_in(e["word_or_phrase"])
      next if forms.empty?

      Candidate.new(entry_id: e["id"], irish: e["word_or_phrase"].to_s.squish, english: e["translation"].to_s.squish.presence,
                    audio_url: e["audio_url"], speaker: e.dig("speaker", "name")&.squish, dialect: e.dig("speaker", "dialect"),
                    confirmed: e["status"].to_s != "unconfirmed", forms: forms, places: forms.map { |f| speakers[IrishText.words(f).first].size }.max)
    end
    candidates.sort_by { |c| [ c.confirmed ? 0 : 1, -c.places, c.irish.length ] }
  end
end
