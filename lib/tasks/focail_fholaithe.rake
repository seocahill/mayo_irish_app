# frozen_string_literal: true

require "json"
require "yaml"

# Mayo entries from Focail Fholaithe (focailfholaithe.fng.ie, counties/8651),
# a collection of rare dialect words made freely available by the RIA for
# non-commercial use. Only a hand-curated selection is imported; see
# data/focail_fholaithe/mayo_lesson_plan.yml for what was kept and why.
#
#   rake focail_fholaithe:import
#
# Idempotent. Lessons are created unpublished (numbers 801+, clear of the
# curriculum and the extraction routine) so an admin can review and publish.
namespace :focail_fholaithe do
  FOCAIL_DIR = Rails.root.join("data", "focail_fholaithe")
  FOCAIL_TITLE_PREFIX = "Focail Fholaithe:"
  FOCAIL_SOURCE_NOTE = <<~HTML
    <p>These are dialect words recorded from Mayo Irish for the <em>Focail Fholaithe</em> ("hidden words") project (Royal Irish Academy), made freely available for non-commercial use.</p>
    <p>Many of the entries were recorded by Éamon Mac an Fhailigh (<em>Liosta Focal as Iorras</em>, 1978). Spellings and English glosses are as the collectors gave them, and pronunciations are given only where the source has one. Many of these are rare or local words, so expect some you won't hear outside Mayo.</p>
  HTML
  # [column, label] for what goes in a word's notes, in this order. A district of "Ní fios" means unknown.
  FOCAIL_NOTE_FIELDS = [
    ["alternative_forms", "Also"],
    ["grammar_forms", "Grammar"],
    ["meaning_ga", "In Irish"],
    ["usage", "In use"],
    ["notes", "Note"],
    ["district", "District"]
  ].freeze

  desc "Create unpublished vocabulary lessons from the curated Mayo Focail Fholaithe entries"
  task import: :environment do
    entries = JSON.parse(File.read(FOCAIL_DIR.join("mayo_entries.json"))).index_by { |e| e["position"] }
    plan = YAML.load_file(FOCAIL_DIR.join("mayo_lesson_plan.yml"))

    plan.each do |spec|
      lesson = Lesson.find_or_initialize_by(number: spec["number"])
      if lesson.persisted? && !lesson.title.start_with?(FOCAIL_TITLE_PREFIX)
        abort "Lesson #{lesson.number} already exists and is not a Focail Fholaithe lesson (#{lesson.title.inspect})"
      end

      lesson.assign_attributes(title: spec["title"], position: spec["number"], lesson_type: "thematic_vocab")
      lesson.published = false if lesson.new_record?
      lesson.save!

      if lesson.lesson_blocks.empty?
        lesson.lesson_blocks.create!(position: 0, block_type: "text", caption: "About this word list", body: FOCAIL_SOURCE_NOTE)
      end

      words = spec["positions"].map { |position| entries.fetch(position) }.group_by { |e| e["headword"] }
      words.each_with_index do |(headword, rows), index|
        item = lesson.vocabulary_items.find_or_initialize_by(irish: headword)
        notes = rows.flat_map do |row|
          FOCAIL_NOTE_FIELDS.filter_map do |column, label|
            value = row[column].presence
            "#{label}: #{value}" if value && value != "Ní fios"
          end
        end
        item.assign_attributes(
          english: rows.filter_map { |r| r["meaning_en"] }.join("; "),
          phonetic: rows.filter_map { |r| r["pronunciation"].presence }.first,
          notes: notes.join("\n").presence,
          gender: nil,
          position: index
        )
        item.save!
      end

      puts "  #{lesson.number}. #{lesson.title} — #{words.size} words"
    end

    puts "Done. #{plan.size} draft lessons created/updated."
  end
end
