# frozen_string_literal: true

require "json"
require "set"

# Imports entries from files/lessons_full.json into Lessons numbered 201+.
# Entries are grouped by dominant tag family and split into chunks of ≤ 20.
# Run: rake json_lessons:import

namespace :json_lessons do
  JSON_PATH        = Rails.root.join("files", "lessons_full.json")
  LESSON_OFFSET    = 201
  CHUNK_SIZE       = 20

  # Tag-to-group priority list — first matching group wins.
  TAG_GROUPS = [
    ["Verbs", %w[
      verb verbs irregular-verb irregular abair beir bi caith cluin dean deir
      fagbh fagh faighim fágaim feic feicim fuagair ith ithim leigh maith
      tabhair teigh tig tá ta verbal-noun verb-endings consuetudinal conditional
      future preterite subjunctive s-future dependent-form substantive-verb
      tense-aspect suppletion historic-s-form passive participle
    ]],
    ["Nouns & Morphology", %w[
      noun morphology declension noun-class noun-inflection plural plurals
      plural-variant genitive-plural endings ending-ach ending-achan ending-an
      syncope morphological-variant stem-types indeclinable collective
      disyllabic monosyllabic denominative frequentative group-i group-ii group-iii
    ]],
    ["Prepositions", %w[
      preposition prepositional-pronoun prepositional-pronouns prepositions
      preposition-phrase ag ar as de do faoi i idir le o roimh thar tre
    ]],
    ["Phonology", %w[
      phonology phonological-feature phonological-coalescence sandhi coalescence
      elision merger metathesis stress vowel-alternation vowel-substitution
      consonant-mutation consonant-substitution nasalization t-prothesis
      velar-palatal allegro-pausa allegro-form by-forms frozen-form instability
      intervening-j phoneme-inventory lenition eclipsis mutation mutations
      phonetic-variant
    ]],
    ["Grammar & Syntax", %w[
      syntax adjective adverb comparative comparison emphatic conjunction
      interrogative negative pronoun pronouns demonstrative deixis possessive
      possessive-pronouns quantifier cardinal ordinal dual object frame
      1pl-pronoun syntactic-distribution function-word indefinite personal
      optative rhetoric mnemonic mixed-form-da numerals
    ]],
    ["Folklore & Culture", %w[
      folklore supernatural tradition religion prayer charm oath toast wake
      puca banshee cow-legend holy-well place-legend Aesop fable verse proverb
      triad wisdom genealogy biographical kinship pilgrimage commandments
      saints moral fieldwork life-experience folk-knowledge natural-history
    ]],
    ["Geography & Place", %w[
      geography place-name place-lore rivers direction spatial travel astronomy
      vs-erris
    ]],
    ["Social & Daily Life", %w[
      agriculture turf-cutting household tools games sport drink food health
      anatomy body animals birds nature weather fire children friendship
      social-class social-values commerce healing emotion endearment disaster
      death hearing narrative
    ]],
    ["Idioms & Phrases", %w[
      idiom idiom-context idiom-frame phrase formula stereotyped-phrases
      interjection code-switching loanword english-borrowing
    ]],
    ["Dialect & Language Notes", %w[
      dialect-comparison dialect-variation lexical-confusion semantic-extension
      meta language surname surnames rhythm
    ]],
  ].freeze

  SOURCE_LABELS = {
    "foxford" => "Wagner — Foxford dialect notes",
    "erris"   => "Wagner — Erris dialect notes",
  }.freeze

  def self.assign_group(entry)
    entry_tags = Set.new(entry["tags"] || [])
    TAG_GROUPS.each do |name, tag_list|
      return name if entry_tags.intersect?(Set.new(tag_list))
    end
    "Miscellaneous"
  end

  def self.source_label(entry)
    label = SOURCE_LABELS.fetch(entry["source"].to_s, entry["source"].to_s.capitalize)
    page  = entry["page"]
    page ? "#{label}, p. #{page}" : label
  end

  def self.format_entry_html(entry)
    parts = []

    if entry["headword"].present?
      head = "<strong>#{CGI.escapeHTML(entry['headword'])}</strong>"
      if entry["phonetic_original"].present?
        head += " <span class=\"font-mono text-xs text-stone-500\">/#{CGI.escapeHTML(entry['phonetic_original'])}/</span>"
      end
      if entry["english"].present?
        head += " — #{CGI.escapeHTML(entry['english'])}"
      end
      parts << "<p>#{head}</p>"
    elsif entry["english"].present?
      parts << "<p>#{CGI.escapeHTML(entry['english'])}</p>"
    end

    # Paradigm table
    if (tbl = entry["table"]).present?
      cols  = tbl["columns"] || []
      rows  = tbl["rows"]    || []
      thead = cols.map { |c| "<th class=\"px-2 py-1 text-left\">#{CGI.escapeHTML(c)}</th>" }.join
      tbody = rows.map { |r|
        cells = r.map { |c| "<td class=\"px-2 py-1\">#{CGI.escapeHTML(c.to_s)}</td>" }.join
        "<tr>#{cells}</tr>"
      }.join
      parts << "<table class=\"text-sm border-collapse w-full\"><thead><tr>#{thead}</tr></thead><tbody>#{tbody}</tbody></table>"
    end

    # Examples
    examples = entry["examples"] || []
    if examples.any?
      items = examples.map do |ex|
        irish = ex["irish"].presence    || ""
        eng   = ex["english"].presence  || ""
        note  = ex["gloss_note"].presence
        li    = "<em>#{CGI.escapeHTML(irish)}</em>"
        li   += " — #{CGI.escapeHTML(eng)}" if eng.present?
        li   += "<br><span class=\"text-xs text-stone-400\">#{CGI.escapeHTML(note)}</span>" if note
        "<li>#{li}</li>"
      end
      parts << "<ul>#{items.join}</ul>"
    end

    # Notes
    if entry["notes"].present?
      parts << "<p class=\"note\">#{CGI.escapeHTML(entry['notes'])}</p>"
    end

    # Per-entry source citation
    parts << "<p class=\"text-xs text-stone-400 mt-1\">#{CGI.escapeHTML(source_label(entry))}</p>"

    "<div>#{parts.join}</div>"
  end

  desc "Import lessons_full.json into Lessons 201+ grouped by tag family"
  task import: :environment do
    require "cgi"

    data    = JSON.parse(JSON_PATH.read)
    entries = data["lessons"]

    # Group
    grouped = Hash.new { |h, k| h[k] = [] }
    entries.each { |e| grouped[assign_group(e)] << e }

    # Chunk and number
    lesson_number = LESSON_OFFSET
    lesson_batches = []

    TAG_GROUPS.map(&:first).append("Miscellaneous").each do |group_name|
      group_entries = grouped[group_name]
      next if group_entries.empty?

      parts = group_entries.each_slice(CHUNK_SIZE).to_a
      parts.each_with_index do |part_entries, idx|
        title = parts.size > 1 ? "#{group_name} (Part #{idx + 1})" : group_name
        lesson_batches << { number: lesson_number, title: title, entries: part_entries }
        lesson_number += 1
      end
    end

    puts "Creating #{lesson_batches.size} lessons (#{LESSON_OFFSET}–#{lesson_number - 1})…"

    lesson_batches.each do |batch|
      lesson = Lesson.find_or_initialize_by(number: batch[:number])

      # Source attribution for the lesson
      source_refs = batch[:entries].filter_map { |e|
        SOURCE_LABELS[e["source"].to_s]
      }.uniq.sort
      attribution = "Source: #{source_refs.join(' & ')} — imported from lessons_full.json"
      lesson.assign_attributes(
        title:        batch[:title],
        position:     batch[:number],
        content_html: attribution,
      )
      lesson.save!

      vocab_pos = 0
      block_pos = 0

      batch[:entries].each do |entry|
        if entry["type"] == "vocabulary" && entry["headword"].present?
          irish = entry["headword"].to_s.strip
          item  = lesson.vocabulary_items.find_or_initialize_by(irish: irish)
          item.assign_attributes(
            english:  entry["english"].to_s,
            phonetic: entry["phonetic_original"].to_s,
            position: vocab_pos,
          )
          item.save!
          vocab_pos += 1
        else
          block = lesson.lesson_blocks.find_or_initialize_by(position: block_pos)
          block.block_type = "text"
          block.caption    = entry["headword"].presence
          block.body       = format_entry_html(entry)
          block.save!
          block_pos += 1
        end
      end

      puts "  #{batch[:number]}. #{batch[:title]} — #{batch[:entries].size} entries"
    end

    puts "Done. #{lesson_batches.size} lessons created/updated."
  end
end
