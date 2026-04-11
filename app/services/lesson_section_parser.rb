require 'openai'

# Parses the raw OCR text fields of a lesson into structured LessonRow records
# using OpenAI. Also corrects garbled Irish characters from poor OCR.
class LessonSectionParser
  GRAMMAR_PROMPT = <<~PROMPT
    You are parsing OCR-extracted text from a Mayo Irish (Gaeilge Chonnacht) textbook.
    The OCR is poor — accented Irish characters (á é í ó ú Á É Í Ó Ú) are mangled into plain ASCII.
    Reconstruct correct Irish spelling throughout.

    Your job: convert the grammar section into a flat JSON array of rows.
    Each row has: { "row_type": "...", "col_1": "...", "col_2": "...", "col_3": "..." }

    Use these row_type values:
    - "section_heading"  — a numbered rule title, e.g. "1. IF-CLAUSES TO EXPRESS A CONDITION"
                           Put the full heading in col_1. col_2 and col_3 are null.
    - "subheading"       — a sub-section label like "(i) Positive", "(ii) Forms", "(iii) Pronunciation"
                           Put the label in col_1. col_2 and col_3 are null.
    - "col_header"       — a row of column labels for a table, e.g. "Before a consonant | Before a vowel | Contrast"
                           Distribute into col_1, col_2, col_3.
    - "data"             — a data row. Use as many of col_1/col_2/col_3 as there are columns in the table.
                           For single-column text/explanation use col_1 only.
    - "note"             — a footnote or italicised explanatory note. Put full text in col_1.

    Rules:
    - Keep Irish examples with their English translations together in the same cell.
    - When a section has a 3-column table (like the possessive adjectives table), each row of that table
      becomes one "data" row with col_1/col_2/col_3 filled appropriately.
    - Prose explanation text becomes "data" rows with col_1 only.
    - Footnote numbers (1, 2 etc.) can be dropped.
    - Return ONLY valid JSON array — no markdown, no ```json, no prose.
  PROMPT

  TEXTS_PROMPT = <<~PROMPT
    You are parsing OCR-extracted text from a Mayo Irish (Gaeilge Chonnacht) textbook.
    The OCR is poor — accented Irish characters are mangled. Correct Irish spelling throughout.

    Parse this reading passage / dialogue into a JSON array of rows.
    Each row: { "row_type": "data", "col_1": "one sentence or short utterance", "col_2": null, "col_3": null }
    The title of the passage (if any) should be row_type "section_heading".
    Return ONLY valid JSON — no markdown, no prose.
  PROMPT

  EXERCISES_PROMPT = <<~PROMPT
    You are parsing OCR-extracted text from a Mayo Irish (Gaeilge Chonnacht) textbook.
    Parse this exercises section into a JSON array of rows.
    Each numbered item becomes one row: { "row_type": "data", "col_1": "exercise sentence", "col_2": null, "col_3": null }
    Return ONLY valid JSON — no markdown, no prose.
  PROMPT

  SECTION_PROMPTS = {
    'grammar'   => GRAMMAR_PROMPT,
    'texts'     => TEXTS_PROMPT,
    'exercises' => EXERCISES_PROMPT
  }.freeze

  def initialize(lesson)
    @lesson = lesson
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.openai.openai_key,
      organization_id: Rails.application.credentials.openai.openai_org
    )
  end

  def parse_all(sections: LessonRow::SECTIONS, replace: true)
    sections.each do |section|
      raw = @lesson.public_send(section)
      next if raw.blank?

      rows = parse_section(section, raw)
      next if rows.empty?

      @lesson.lesson_rows.where(section: section).delete_all if replace

      rows.each_with_index do |row, idx|
        @lesson.lesson_rows.create!(
          section:  section,
          position: idx + 1,
          row_type: row['row_type'] || 'data',
          col_1:    row['col_1'],
          col_2:    row['col_2'],
          col_3:    row['col_3']
        )
      end

      puts "  #{section}: #{rows.size} rows saved"
    end
  end

  private

  def parse_section(section, text)
    prompt = SECTION_PROMPTS.fetch(section)
    response = @client.chat(
      parameters: {
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: prompt },
          { role: 'user', content: text }
        ],
        temperature: 0.1,
        max_tokens: 4096
      }
    )

    content = response.dig('choices', 0, 'message', 'content').to_s.strip
    # Strip any accidental markdown fences
    content = content.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '').strip
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "LessonSectionParser JSON error for #{section}: #{e.message}\nContent: #{content}"
    []
  end
end
