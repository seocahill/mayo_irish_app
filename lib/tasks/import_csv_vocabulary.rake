# frozen_string_literal: true

require "csv"
require "open-uri"

# Thematic vocabulary lessons imported from mayo_irish_vocabulary_with_audio.csv.
# Lessons are numbered from 101 onwards so they never collide with the main curriculum.
#
# Two tasks:
#   rake vocab:import   — creates Lessons + VocabularyItems (fast, idempotent)
#   rake vocab:audio    — downloads audio from Wix and attaches via Active Storage (slow)
#
# Run import first, verify, then run audio.

namespace :vocab do
  CSV_PATH = Rails.root.join("files", "mayo_irish_vocabulary_with_audio.csv")
  LESSON_NUMBER_OFFSET = 37

  desc "Create thematic Lessons and VocabularyItems from the Mayo Irish CSV (no audio download)"
  task import: :environment do
    rows = CSV.read(CSV_PATH, headers: true)
    by_category = rows.group_by { |r| r["category"].to_s.strip }

    puts "Importing #{by_category.size} categories…"

    by_category.each_with_index do |(category, entries), idx|
      number = LESSON_NUMBER_OFFSET + idx
      lesson = Lesson.find_or_initialize_by(number: number)
      lesson.assign_attributes(title: category, position: number, lesson_type: "thematic_vocab")
      lesson.save!

      entries.each_with_index do |row, pos|
        irish   = row["irish"].to_s.strip
        english = row["english"].to_s.strip
        next if irish.blank? || english.blank?

        item = lesson.vocabulary_items.find_or_initialize_by(irish: irish)
        item.assign_attributes(english: english, position: pos)
        item.save!
      end

      puts "  #{number}. #{category} — #{entries.count} items"
    end

    puts "Done. #{by_category.size} lessons created/updated."
  end

  desc "Store Wix audio URLs directly on VocabularyItems (no download)"
  task urls: :environment do
    rows = CSV.read(CSV_PATH, headers: true).select { |r| r["audio"].present? }

    puts "Setting audio URLs for #{rows.size} entries…"

    ok = 0
    skipped = 0

    rows.each do |row|
      irish = row["irish"].to_s.strip
      url   = row["audio"].to_s.strip

      item = VocabularyItem
               .joins(:lesson)
               .where(lessons: { number: LESSON_NUMBER_OFFSET.. })
               .find_by(irish: irish)

      unless item
        warn "  SKIP (not found): #{irish}"
        skipped += 1
        next
      end

      item.update_column(:audio_url, url)
      ok += 1
    end

    puts "Done. updated=#{ok}  skipped=#{skipped}"
  end

  desc "Download Wix-hosted audio and attach to VocabularyItems via Active Storage"
  task audio: :environment do
    rows = CSV.read(CSV_PATH, headers: true).select { |r| r["audio"].present? }

    puts "Fetching audio for #{rows.size} entries…"

    ok = 0
    skipped = 0
    failed = 0

    rows.each do |row|
      irish = row["irish"].to_s.strip
      url   = row["audio"].to_s.strip

      # Find the item across all thematic lessons (numbers 101+)
      item = VocabularyItem
               .joins(:lesson)
               .where(lessons: { number: LESSON_NUMBER_OFFSET.. })
               .find_by(irish: irish)

      unless item
        warn "  SKIP (not found): #{irish}"
        skipped += 1
        next
      end

      if item.audio.attached?
        skipped += 1
        next
      end

      begin
        # rubocop:disable Security/Open
        io = URI.open(url, read_timeout: 15)
        # rubocop:enable Security/Open
        filename = "#{irish.parameterize(separator: '_')}_#{item.id}.mp3"
        item.audio.attach(io: io, filename: filename, content_type: "audio/mpeg")
        ok += 1
        print "."
        $stdout.flush
        sleep 0.05 # be polite to Wix
      rescue => e
        failed += 1
        warn "\n  FAIL: #{irish} — #{e.message}"
      end
    end

    puts "\nDone. attached=#{ok}  skipped=#{skipped}  failed=#{failed}"
  end
end
