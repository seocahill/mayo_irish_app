# Finds real Mayo recordings of a vocabulary word on Abairt and saves the best
# few as suggestions, each checked with ABAIR's recogniser. Runs once per word;
# after that the saved suggestions are what an editor reviews.
#
#   RecordingSuggester.new(vocabulary_item).call  # => the word's suggestions
class RecordingSuggester
  def initialize(item, abairt: AbairtClient.new, abair: AbairClient.new)
    @item = item
    @abairt = abairt
    @abair = abair
  end

  def call
    fetch if @item.recordings_searched_at.nil?
    @item.recording_suggestions.best_first
  end

  private

  def fetch
    attributes = candidates.first(RecordingSuggestion::PER_WORD).map { |entry| suggestion_attributes(entry) }

    VocabularyItem.transaction do
      attributes.each { |a| @item.recording_suggestions.create!(a) }
      @item.update!(recordings_searched_at: Time.current)
    end
  end

  # Only entries that really contain the word, exact recordings of it first.
  def candidates
    @abairt.recordings_of(@item.irish)
           .select { |entry| entry["audio_url"].present? && IrishText.includes?(entry["word_or_phrase"], @item.irish) }
           .sort_by { |entry| [ IrishText.same?(entry["word_or_phrase"], @item.irish) ? 0 : 1, IrishText.words(entry["word_or_phrase"]).size ] }
  end

  def suggestion_attributes(entry)
    check = check_of(entry)
    {
      abairt_entry_id: entry["id"],
      irish: entry["word_or_phrase"].to_s.squish,
      english: entry["translation"].to_s.squish.presence,
      audio_url: entry["audio_url"],
      speaker_name: entry.dig("speaker", "name")&.squish,
      speaker_dialect: entry.dig("speaker", "dialect"),
      heard: check&.heard,
      check_passed: check&.passed? || false
    }
  end

  # A clip that can't be fetched or recognised is still suggested, unchecked.
  def check_of(entry)
    RecordingCheck.new(entry["audio_url"], word: @item.irish, abair: @abair)
  rescue AbairClient::Error => e
    Rails.logger.warn("[recordings] couldn't check Abairt entry #{entry["id"]}: #{e.message}")
    nil
  end
end
