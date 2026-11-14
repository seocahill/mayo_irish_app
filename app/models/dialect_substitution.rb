# A designer-entered pair: a Connemara (or standard) form found in the course
# skeleton and the Mayo form that should replace it, with where each comes
# from. The app never writes these; it only finds where the other form turns
# up so a designer can decide.
class DialectSubstitution < ApplicationRecord
  validates :other_form, :mayo_form, presence: true

  scope :ordered, -> { order(Arel.sql("LOWER(other_form)")) }

  Hit = Struct.new(:substitution, :place, :text, :path, keyword_init: true)

  # Where the other forms appear in a lesson: its vocabulary, grammar rules,
  # text blocks and intro transcript. Proposals only; nothing is changed.
  def self.hits_in(lesson)
    substitutions = ordered.to_a
    return [] if substitutions.empty?

    found = []
    each_text(lesson) do |place, text, path|
      substitutions.each do |s|
        found << Hit.new(substitution: s, place: place, text: text, path: path) if IrishText.includes?(text, s.other_form)
      end
    end
    found
  end

  def self.each_text(lesson)
    lesson.vocabulary_items.each do |v|
      yield "#{I18n.t('dialect_substitutions.places.vocabulary')}: #{v.irish}", [ v.irish, v.plural, v.notes ].compact.join(" "), nil
    end
    lesson.grammar_rules.includes(:grammar_sections).each do |rule|
      yield "#{I18n.t('dialect_substitutions.places.grammar')}: #{rule.title}", [ rule.body.to_plain_text, *rule.grammar_sections.map { |s| s.body.to_plain_text } ].join(" "), Rails.application.routes.url_helpers.edit_grammar_rule_path(rule)
    end
    lesson.lesson_blocks.select(&:text?).each do |block|
      yield "#{I18n.t('dialect_substitutions.places.text')}: #{block.caption.presence || block.id}", block.body.to_plain_text, Rails.application.routes.url_helpers.edit_lesson_block_path(block)
    end
    yield I18n.t("dialect_substitutions.places.intro"), lesson.intro_video_transcript.to_s, nil
  end

  # Prompt lines for the AI conversation: use the Mayo form, not the other.
  def self.prompt_note
    pairs = ordered.map { |s| "#{s.other_form} → #{s.mayo_form}" }
    return if pairs.empty?

    "MAYO FORMS: where you would use a form on the left, use the Mayo form on the right instead:\n#{pairs.join("\n")}"
  end
end
