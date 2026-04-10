require 'openai'

# Parses the raw OCR text fields of a lesson into structured LessonRow records
# using OpenAI. Also corrects garbled Irish characters from poor OCR.
class LessonSectionParser
  SECTION_PROMPTS = {
    'grammar' => <<~PROMPT,
      You are parsing OCR-extracted text from an Irish language textbook (Mayo Irish / Gaeilge Chonnacht).
      The OCR quality is poor — accented Irish characters (á é í ó ú Á É Í Ó Ú) are often mangled
      into plain ASCII (e.g. 'a' instead of 'á', 'o' instead of 'ó'). Correct them using your knowledge
      of Irish spelling.

      Parse the following grammar section text into a JSON array of rows.
      Each row represents one numbered grammar rule or sub-point.
      Each row has: { "col_1": "rule title or heading", "col_2": "explanation and examples" }
      Sub-points like (i), (ii) should be merged into the main rule's col_2.
      Return ONLY valid JSON — no markdown, no prose, no ```json wrapper.
    PROMPT

    'texts' => <<~PROMPT,
      You are parsing OCR-extracted text from an Irish language textbook (Mayo Irish / Gaeilge Chonnacht).
      The OCR quality is poor — accented Irish characters (á é í ó ú Á É Í Ó Ú) are often mangled.
      Correct them using your knowledge of Irish spelling and vocabulary.

      Parse the following reading text / dialogue into a JSON array of rows.
      Each row is one sentence or short exchange. Preserve paragraph structure roughly.
      Each row has: { "col_1": "Irish sentence or line" }
      Return ONLY valid JSON — no markdown, no prose, no ```json wrapper.
    PROMPT

    'exercises' => <<~PROMPT
      You are parsing OCR-extracted text from an Irish language textbook (Mayo Irish / Gaeilge Chonnacht).
      The OCR quality is poor — accented Irish characters may be mangled. Correct Irish words accordingly.

      Parse the following exercises section into a JSON array of rows.
      Each row is one numbered exercise sentence.
      Each row has: { "col_1": "exercise text (English sentence to translate)" }
      Return ONLY valid JSON — no markdown, no prose, no ```json wrapper.
    PROMPT
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

      if replace
        @lesson.lesson_rows.where(section: section).delete_all
      end

      rows.each_with_index do |row, idx|
        @lesson.lesson_rows.create!(
          section: section,
          position: idx + 1,
          col_1: row['col_1'],
          col_2: row['col_2'],
          col_3: row['col_3']
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
        temperature: 0.1
      }
    )

    content = response.dig('choices', 0, 'message', 'content').to_s.strip
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "LessonSectionParser JSON error for #{section}: #{e.message}\nContent: #{content}"
    []
  end
end
