# lib/tasks/grammar_import.rake
#
# Converts the raw OCR grammar text stored in lessons.grammar into a structured
# JSON representation stored in lessons.grammar_data.
#
# Usage:
#   bin/rails grammar:import            # all lessons
#   bin/rails grammar:import[2]         # single lesson by number
#   bin/rails grammar:import[2,force]   # re-import even if grammar_data exists

namespace :grammar do
  desc "Parse OCR grammar text into structured JSON (lessons.grammar_data)"
  task :import, [:lesson_number, :mode] => :environment do |_t, args|
    scope = if args[:lesson_number].present?
              Lesson.where(number: args[:lesson_number].to_i)
            else
              Lesson.ordered
            end
    force = args[:mode] == "force"

    parser = GrammarTextParser.new
    updated = 0

    scope.each do |lesson|
      next if lesson.grammar.blank?
      next if lesson.grammar_structured? && !force

      sections = parser.parse(lesson.grammar)
      lesson.update_column(:grammar_data, sections.to_json)
      puts "  Lesson #{lesson.number}: #{lesson.title} — #{sections.size} section(s)"
      updated += 1
    end

    puts "\nDone. #{updated} lesson(s) imported."
  end
end

# ── Parser class ─────────────────────────────────────────────────────────────
#
# Converts flat OCR text into the grammar_data JSON structure:
#
#   [ { "number"=>"1", "title"=>"...", "blocks"=>[...] }, ... ]
#
# Block types:
#   { "type"=>"subsection", "label"=>"(i)", "title"=>"..." }
#   { "type"=>"prose",      "text"=>"..." }
#   { "type"=>"examples",   "rows"=>[["irish","english"], ...] }
#   { "type"=>"table",      "headers"=>[...], "rows"=>[[...], ...], "note"=>"..." }
#   { "type"=>"note",       "text"=>"..." }
#
class GrammarTextParser
  SECTION_RE    = /\A(\d+)\.\s+(.+)\z/
  SUBSECTION_RE = /\A\(([ivxlcdmIVXLCDM]+)\)\s*(.*)\z/

  # Known table header patterns that follow a "(i) Forms" subsection
  TABLE_HEADER_WORDS = %w[Before After Between Consonant Vowel Contrast Form
                           Type Class Ending masculine feminine singular plural].freeze

  # Common English sentence starters used to detect Irish/English split points
  ENGLISH_STARTERS = /\A(I |You |He |She |It |We |They |The |A |An |There |
                         That |This |Are |Is |Not |No |One |People |In |At |On |To |
                         If |When |Both |Neither |All |Note )/xi.freeze

  def parse(text)
    raw_sections = split_sections(text)
    raw_sections.map do |sec|
      {
        "number" => sec[:number],
        "title"  => sec[:title],
        "blocks" => build_blocks(sec[:lines])
      }
    end
  end

  private

  # ── Section splitting ──────────────────────────────────────────────────────

  def split_sections(text)
    sections = []
    current  = nil

    text.split("\n").each do |raw|
      line = raw.rstrip
      if (m = line.match(SECTION_RE))
        sections << current if current
        current = { number: m[1], title: m[2], lines: [] }
      elsif current
        current[:lines] << line
      end
    end
    sections << current if current
    sections
  end

  # ── Block building (within a section) ─────────────────────────────────────

  def build_blocks(lines)
    blocks     = []
    current    = []
    prev_was_subsection = false

    flush = lambda do
      next if current.empty?
      group = current.reject { |l| l.strip.empty? }
      blocks.concat(classify_group(group, prev_was_subsection)) unless group.empty?
      current.clear
      prev_was_subsection = false
    end

    lines.each do |line|
      if (m = line.match(SUBSECTION_RE))
        flush.call
        blocks << { "type" => "subsection", "label" => "(#{m[1]})", "title" => m[2].strip }
        prev_was_subsection = true
      elsif line.strip.empty?
        flush.call
      else
        current << line
      end
    end
    flush.call

    blocks
  end

  # ── Group classification ───────────────────────────────────────────────────

  # Decides whether a group of lines is a table, examples, prose, or note.
  def classify_group(lines, after_subsection)
    return [] if lines.empty?

    first = lines.first.strip

    # Footnote / note: starts with a superscript digit, asterisk, or "Note"
    if first.match?(/\A(\d|[*†‡]|Note |iln |JThe |\^This )/) && lines.size <= 4
      return [{ "type" => "note", "text" => lines.join(" ").strip }]
    end

    avg_len = lines.sum { |l| l.length }.to_f / lines.size

    # Table: first line looks like column headers (no periods, known header words)
    if after_subsection && looks_like_table_header?(first) && lines.size > 1
      return [build_table_block(lines)]
    end

    # Examples: short average line length
    if avg_len < 90
      return [build_examples_block(lines)]
    end

    # Prose: join continuation lines
    [build_prose_block(lines)]
  end

  def looks_like_table_header?(line)
    return false if line.include?(".")
    words = line.split(/\s+/).map(&:capitalize)
    (words & TABLE_HEADER_WORDS).any?
  end

  # ── Block builders ─────────────────────────────────────────────────────────

  def build_table_block(lines)
    header_line = lines.first.strip
    data_lines  = lines[1..]

    # Split the header line into column headers by looking for recognizable
    # multi-word phrases (e.g. "Before a consonant", "Before a vowel", "Contrast")
    headers = detect_column_headers(header_line)

    # Separate a trailing note (starts with "Note")
    note_idx = data_lines.rindex { |l| l.strip.match?(/\ANote /) }
    note_text = nil
    if note_idx
      note_text  = data_lines[note_idx..].map(&:strip).join(" ")
      data_lines = data_lines[0...note_idx]
    end

    rows = data_lines.reject { |l| l.strip.empty? }.map { |l| [l.strip] }

    block = { "type" => "table", "headers" => headers, "rows" => rows }
    block["note"] = note_text if note_text
    block
  end

  def detect_column_headers(line)
    # Try to split "Before a consonant Before a vowel Contrast" into 3 parts
    # by matching known column header phrases
    patterns = [
      /Before a consonant/i,
      /Before a vowel/i,
      /After a vowel/i,
      /Contrast/i,
      /Forms?/i,
      /Positive/i,
      /Negative/i,
      /Singular/i,
      /Plural/i,
      /Masculine/i,
      /Feminine/i
    ]

    found = patterns.select { |p| line.match?(p) }.map { |p| line.match(p)[0] }
    found.any? ? found : [line]
  end

  def build_examples_block(lines)
    rows = lines.map do |line|
      irish, english = split_irish_english(line.strip)
      [irish, english]
    end
    { "type" => "examples", "rows" => rows }
  end

  def build_prose_block(lines)
    # Join wrapped lines into a single paragraph, respecting sentence flow.
    # A line is a continuation if the previous line doesn't end with sentence
    # punctuation and this line starts with a lowercase letter.
    paragraphs = []
    current_para = []

    lines.each do |line|
      stripped = line.strip
      if stripped.empty?
        paragraphs << current_para.join(" ") unless current_para.empty?
        current_para = []
      elsif current_para.any? && continues_sentence?(current_para.last, stripped)
        current_para << stripped
      else
        paragraphs << current_para.join(" ") unless current_para.empty?
        current_para = [stripped]
      end
    end
    paragraphs << current_para.join(" ") unless current_para.empty?

    paragraphs.reject(&:empty?).map { |p| { "type" => "prose", "text" => p } }
  end

  # A line continues the previous if the previous ended without sentence
  # punctuation, or this line starts with a lowercase letter.
  def continues_sentence?(prev_line, this_line)
    !prev_line.match?(/[.?!]\z/) || this_line.match?(/\A[a-z]/)
  end

  # ── Irish / English splitter ───────────────────────────────────────────────
  #
  # Tries to find where the Irish sentence(s) end and the English translation
  # begins on the same line.  Works right-to-left through sentence boundaries.

  def split_irish_english(line)
    # Find all sentence boundary positions: ". ", "? ", "! "
    boundaries = []
    line.scan(/[.?!]\s+/) { boundaries << [$~.begin(0), $~.end(0)] }

    # Try from rightmost boundary leftward
    boundaries.reverse.each do |punct_end, after_start|
      candidate = line[after_start..].to_s.strip
      next if candidate.empty?
      # Accept split if the English candidate starts with a known English starter
      # and does not begin with a common Irish verb form
      if candidate.match?(ENGLISH_STARTERS) && !irish_start?(candidate)
        irish   = line[0..punct_end].strip
        english = candidate
        return [irish, english]
      end
    end

    # Last-resort: split at the last ". " before an uppercase word
    if (m = line.match(/^(.+\S)\.\s+([A-Z].{4,})$/))
      return [m[1] + ".", m[2]]
    end

    # Can't split — store whole line in Irish column
    [line, ""]
  end

  IRISH_VERBS = /\A(Tá|Táim|Nil|Nilaim|An bhfuil|Nach bhfuil|Feicim|Cloisim|
                    Tigim|Deir|Bhí|Beidh|Cén|Cad|Cá |Go bhfuil|Mar)/xi.freeze

  def irish_start?(text)
    text.match?(IRISH_VERBS) || text.match?(/[áéíóúÁÉÍÓÚ]/)
  end
end
