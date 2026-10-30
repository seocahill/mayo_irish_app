# Builds unpublished vocabulary lessons from the Mayo entries of Focail Fholaithe
# (focailfholaithe.fng.ie, counties/8651): rare dialect words, made freely
# available by the Royal Irish Academy for non-commercial use. The entries are in
# data/focail_fholaithe/mayo_entries.json and which of them go in which lesson is
# in mayo_lesson_plan.yml. Safe to run again: lessons and words are matched by
# number and Irish spelling and updated in place.
#
#   FocailFholaitheImport.from_files.call  # => the lessons, still unpublished
class FocailFholaitheImport
  class Conflict < StandardError; end

  DIR = Rails.root.join("data", "focail_fholaithe")
  TITLE_PREFIX = "Focail Fholaithe:"
  BLOCK_CAPTION = "About this word list"
  UNKNOWN_AREA = "Ní fios"
  PLURAL = /\Aplur\.\s*(\S+)\z/
  # Longer notes are scholarly passages (a quoted survey letter, say), not something to show under a word.
  MAX_NOTE_LENGTH = 500
  SOURCE_NOTE = <<~HTML
    <p>These words come from <em>Focail Fholaithe</em> ("hidden words"), a collection of rare Irish dialect words made freely available by the Royal Irish Academy for non-commercial use. This list is the Mayo section.</p>
    <p>Where the source has a full record for a word, it names the collection (<em>Liosta Focal as Iorras</em>, "words from Erris"), the collector (Éamon Mac an Fhailigh) and the year (1978). Under each word you will see the collector's own notes: examples of use, alternative forms, and the area when the source gives one. Pronunciations are in the collector's own phonetic notation.</p>
    <p>Spellings and English glosses are as the collector gave them. Many of these are rare or local words, so expect some you won't hear outside Mayo.</p>
  HTML

  def self.from_files
    new(entries: JSON.parse(DIR.join("mayo_entries.json").read), plan: YAML.load_file(DIR.join("mayo_lesson_plan.yml")))
  end

  def initialize(entries:, plan:)
    @entries = entries.index_by { |entry| entry["position"] }
    @plan = plan
  end

  def call
    Lesson.transaction { @plan.map { |spec| import(spec) } }
  end

  private

  def import(spec)
    lesson = Lesson.find_or_initialize_by(number: spec["number"])
    if lesson.persisted? && !lesson.title.start_with?(TITLE_PREFIX)
      raise Conflict, "Lesson #{lesson.number} already exists and is not a Focail Fholaithe lesson (#{lesson.title.inspect})"
    end

    lesson.assign_attributes(title: spec["title"], position: spec["number"], lesson_type: "thematic_vocab")
    lesson.published = false if lesson.new_record?
    lesson.save!

    lesson.lesson_blocks.find_or_initialize_by(caption: BLOCK_CAPTION).update!(position: 0, block_type: "text", body: SOURCE_NOTE)
    words(spec["positions"]).each_with_index { |(headword, rows), index| write_word(lesson, headword, rows, index) }
    lesson
  end

  # Entries sharing a headword become one word.
  def words(positions)
    positions.map { |position| @entries.fetch(position) }.group_by { |entry| entry["headword"] }
  end

  def write_word(lesson, headword, rows, index)
    lesson.vocabulary_items.find_or_initialize_by(irish: headword).update!(
      english: rows.filter_map { |row| gloss(row["meaning_en"]) }.join("; "),
      phonetic: rows.filter_map { |row| phonetic(row["pronunciation"]) }.first,
      plural: rows.filter_map { |row| row["grammar_forms"]&.match(PLURAL)&.[](1) }.first,
      notes: rows.flat_map { |row| note_lines(row) }.uniq.join("\n").presence,
      gender: nil,
      position: index
    )
  end

  def gloss(text) = text&.sub(/[\s,;:]+\z/, "")

  def phonetic(text) = text&.gsub(%r{\A/\s*|\s*/\z}, "/")

  def note_lines(row)
    [
      ("In use: #{row['usage']}" if row["usage"]),
      ("Irish meaning: #{row['meaning_ga']}" if row["meaning_ga"]),
      ("Also: #{row['alternative_forms']}" if row["alternative_forms"]),
      ("Forms: #{row['grammar_forms']}" if row["grammar_forms"] && !row["grammar_forms"].match?(PLURAL)),
      ("Note: #{row['notes']}" if row["notes"]),
      ("Area: #{row['district']}" if row["district"] && row["district"] != UNKNOWN_AREA)
    ].compact.select { |line| line.size <= MAX_NOTE_LENGTH }
  end
end
