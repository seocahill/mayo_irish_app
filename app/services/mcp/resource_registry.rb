module Mcp
  # Maps the MCP-exposed resource names to their models and the attributes the
  # connector is allowed to write. This allowlist is the main write guardrail:
  # anything not listed here is ignored, so the connector can never touch
  # sensitive columns (timestamps, ids it shouldn't set, `published`, etc.).
  #
  # `published` is deliberately absent from `lessons` — the connector creates
  # drafts (see Tools::CreateRecord) but only a human can publish them from the
  # admin UI.
  module ResourceRegistry
    module_function

    WRITABLE = {
      "lessons" => %w[title number position lesson_type grammar texts exercises
                      vocabulary_notes vocabulary_notes_content tutor_prompt],
      "vocabulary_items" => %w[lesson_id irish english phonetic plural gender notes position audio_url],
      "grammar_rules" => %w[lesson_id number position title body],
      "grammar_sections" => %w[grammar_rule_id label position body],
      "text_passages" => %w[lesson_id title position body],
      "exercises" => %w[lesson_id number position prompt answer],
      "phrases" => %w[lesson_id irish english position audio_url],
      "lesson_blocks" => %w[lesson_id block_type caption position url body]
    }.freeze

    RESOURCES = WRITABLE.keys.freeze

    def resources
      RESOURCES
    end

    def include?(resource)
      RESOURCES.include?(resource.to_s)
    end

    def model_for(resource)
      resource.to_s.classify.constantize
    end

    def writable_attributes(resource)
      WRITABLE.fetch(resource.to_s, [])
    end
  end
end
