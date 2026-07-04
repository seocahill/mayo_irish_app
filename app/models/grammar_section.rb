class GrammarSection < ApplicationRecord
  include Searchable

  belongs_to :grammar_rule
  has_many :phrases, as: :source, dependent: :destroy

  has_rich_text :body

  searchable title: ->(s) { s.label.presence || s.grammar_rule&.title },
             body: ->(s) { [s.label, s.body&.to_plain_text] },
             lesson_number: ->(s) { s.grammar_rule&.lesson&.number }
end
