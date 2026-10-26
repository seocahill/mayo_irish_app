class GrammarSection < ApplicationRecord
  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(s) { s.grammar_rule&.lesson_id },
                            label: ->(s) { s.label.presence || s.grammar_rule&.title }

  belongs_to :grammar_rule
  has_many :phrases, as: :source, dependent: :destroy

  has_rich_text :body

  searchable title: ->(s) { s.label.presence || s.grammar_rule&.title },
             body: ->(s) { [s.label, s.body&.to_plain_text] },
             lesson_number: ->(s) { s.grammar_rule&.lesson&.number }
end
