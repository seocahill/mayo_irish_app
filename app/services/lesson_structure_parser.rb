require 'openai'

# Parses raw OCR text from a lesson into the full structured data model:
# GrammarRule > GrammarSection (with rich text body), TextPassage, Exercise, Phrase
class LessonStructureParser
  PROMPT = <<~PROMPT
    You are converting OCR-extracted text from a Mayo Irish (Gaeilge Chonnacht) textbook
    into structured JSON. The OCR is poor — accented Irish characters (á é í ó ú Á É Í Ó Ú)
    are mangled into plain ASCII. Reconstruct correct Irish spelling throughout.

    Return a single JSON object with these keys:

    "grammar_rules": array of {
      "number": integer,
      "title": string,                    -- e.g. "POSSESSIVE ADJECTIVES"
      "position": integer,
      "body_html": string or null,        -- intro prose for the rule as HTML, if any
      "sections": array of {
        "label": string or null,          -- "(i) Forms", "(ii) Pronunciation", null if no label
        "position": integer,
        "body_html": string               -- ALL section content as HTML — nothing omitted.
                                          -- Include every Irish example, its English translation,
                                          -- every prose explanation, and every footnote.
                                          -- Use <table> for tabular data, <p> for prose,
                                          -- <p class='note'> for footnotes.
                                          -- Irish+English pairs: <p><strong>Irish sentence</strong> — English translation</p>
      },
      "phrases": array of {               -- ALSO extract Irish example sentences separately here
                                          -- (in addition to including them in body_html above)
        "irish": string,
        "english": string or null,
        "position": integer
      }
    }

    "text_passages": array of {
      "title": string or null,            -- e.g. "AG AN DOCHTÚR"
      "position": integer,
      "body_html": string,                -- full passage as HTML with <p> per sentence
      "phrases": array of {               -- every Irish sentence in the passage
        "irish": string,
        "english": string or null,
        "position": integer
      }
    }

    "exercises": array of {
      "number": integer,
      "prompt": string,                   -- English sentence to translate
      "answer": null,
      "position": integer
    }

    "vocabulary_notes_html": string or null  -- cleaned HTML for vocab notes section

    Rules:
    - body_html must be valid HTML fragments (no <html>/<body> wrapper)
    - Tables must use <table><thead><tr><th>..</th></tr></thead><tbody><tr><td>..</td></tr></tbody></table>
    - Correct all Irish spellings — this is the most important task
    - Extract every Irish sentence or example phrase into the phrases arrays
    - Return ONLY valid JSON — no markdown, no backticks, no explanation
  PROMPT

  def initialize(lesson)
    @lesson = lesson
    @client = OpenAI::Client.new(
      access_token: Rails.application.credentials.openai.openai_key,
      organization_id: Rails.application.credentials.openai.openai_org
    )
  end

  def parse(replace: true)
    parts = []
    parts << "=== VOCABULARY NOTES ===\n#{@lesson.vocabulary_notes}" if @lesson.vocabulary_notes.present?
    parts << "=== GRAMMAR ===\n#{@lesson.grammar}" if @lesson.grammar.present?
    parts << "=== TEXTS ===\n#{@lesson.read_attribute(:texts)}" if @lesson.read_attribute(:texts).present?
    parts << "=== EXERCISES ===\n#{@lesson.read_attribute(:exercises)}" if @lesson.read_attribute(:exercises).present?
    raw = parts.join("\n\n")

    return if raw.blank?

    puts "  Calling OpenAI..."
    response = @client.chat(
      parameters: {
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: PROMPT },
          { role: 'user', content: raw }
        ],
        temperature: 0.1,
        max_tokens: 8192
      }
    )

    content = response.dig('choices', 0, 'message', 'content').to_s.strip
    content = content.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '').strip
    data = JSON.parse(content)

    ActiveRecord::Base.transaction do
      if replace
        @lesson.grammar_rules.destroy_all
        @lesson.text_passages.destroy_all
        @lesson.exercises.destroy_all
        @lesson.phrases.destroy_all
      end

      # Vocabulary notes
      if data['vocabulary_notes_html'].present?
        @lesson.update_column(:vocabulary_notes, data['vocabulary_notes_html'])
      end

      # Grammar rules
      Array(data['grammar_rules']).each do |rule_data|
        rule = @lesson.grammar_rules.create!(
          number:   rule_data['number'],
          title:    rule_data['title'],
          position: rule_data['position']
        )
        rule.body = rule_data['body_html'] if rule_data['body_html'].present?
        rule.save!

        Array(rule_data['sections']).each do |sec_data|
          section = rule.grammar_sections.create!(
            label:    sec_data['label'],
            position: sec_data['position']
          )
          section.body = sec_data['body_html'] if sec_data['body_html'].present?
          section.save!

          # Phrases from this section
          Array(sec_data['phrases']).each do |p|
            @lesson.phrases.create!(
              irish:       p['irish'],
              english:     p['english'],
              source:      section,
              position:    p['position']
            )
          end
        end

        # Phrases directly on the rule (grammar examples without a sub-section)
        Array(rule_data['phrases']).each do |p|
          @lesson.phrases.create!(
            irish:    p['irish'],
            english:  p['english'],
            source:   rule,
            position: p['position']
          )
        end
      end

      # Text passages
      Array(data['text_passages']).each do |passage_data|
        passage = @lesson.text_passages.create!(
          title:    passage_data['title'],
          position: passage_data['position']
        )
        passage.body = passage_data['body_html'] if passage_data['body_html'].present?
        passage.save!

        Array(passage_data['phrases']).each do |p|
          @lesson.phrases.create!(
            irish:    p['irish'],
            english:  p['english'],
            source:   passage,
            position: p['position']
          )
        end
      end

      # Exercises
      Array(data['exercises']).each do |ex_data|
        @lesson.exercises.create!(
          number:   ex_data['number'],
          prompt:   ex_data['prompt'],
          answer:   ex_data['answer'],
          position: ex_data['position']
        )
      end
    end

    puts "  grammar_rules:    #{@lesson.grammar_rules.count}"
    puts "  grammar_sections: #{@lesson.grammar_sections.count}"
    puts "  text_passages:    #{@lesson.text_passages.count}"
    puts "  exercises:        #{@lesson.exercises.count}"
    puts "  phrases:          #{@lesson.phrases.count}"
  rescue JSON::ParserError => e
    Rails.logger.error "LessonStructureParser JSON error: #{e.message}\nContent: #{content&.first(500)}"
    raise
  end
end
