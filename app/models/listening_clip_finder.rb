# Finds short phrases on Abairt in which a Mayo speaker uses a vocabulary word,
# and keeps the shortest few that ABAIR's recogniser confirms, as listening
# clips. Runs once per word; a clip already kept for another word is left to it.
#
#   ListeningClipFinder.new(vocabulary_item).call  # => the word's clips
class ListeningClipFinder
  PER_WORD = 2

  def initialize(item, abairt: AbairtClient.new, abair: AbairClient.new)
    @item = item
    @abairt = abairt
    @abair = abair
  end

  def call
    find if @item.clips_searched_at.nil?
    @item.listening_clips.shortest_first
  end

  private

  def find
    attributes = candidates.lazy.filter_map { |entry| clip_attributes(entry) }.first(PER_WORD)

    VocabularyItem.transaction do
      attributes.each { |a| @item.listening_clips.create!(a) }
      @item.update!(clips_searched_at: Time.current)
    end
  end

  # Phrases using the word, not the word on its own, with a translation to
  # check against afterwards; shortest first.
  def candidates
    entries = @abairt.recordings_of(@item.irish).select { |entry| usable?(entry) }
    taken = ListeningClip.where(abairt_entry_id: entries.pluck("id")).pluck(:abairt_entry_id)

    entries.reject { |entry| taken.include?(entry["id"]) }.sort_by { |entry| word_count(entry) }
  end

  def usable?(entry)
    entry["audio_url"].present? && entry["translation"].present? &&
      ListeningClip::WORDS.cover?(word_count(entry)) && IrishText.includes?(entry["word_or_phrase"], @item.irish)
  end

  def word_count(entry) = IrishText.words(entry["word_or_phrase"]).size

  # Only clips in which the recogniser hears the word and most of the rest of
  # the phrase, since some transcriptions don't match their audio; one that
  # can't be checked is left out.
  def clip_attributes(entry)
    check = RecordingCheck.new(entry["audio_url"], word: @item.irish, abair: @abair)
    return unless check.passed? && check.mostly?(entry["word_or_phrase"])

    {
      abairt_entry_id: entry["id"],
      irish: entry["word_or_phrase"].squish,
      english: entry["translation"].squish,
      audio_url: entry["audio_url"],
      speaker_name: entry.dig("speaker", "name")&.squish,
      speaker_dialect: entry.dig("speaker", "dialect"),
      word_count: word_count(entry),
      heard: check.heard
    }
  rescue AbairClient::Error => e
    Rails.logger.warn("[listening] couldn't check Abairt entry #{entry["id"]}: #{e.message}")
    nil
  end
end
