class GrammarSection < ApplicationRecord
  belongs_to :grammar_rule
  has_many :phrases, as: :source, dependent: :destroy

  has_rich_text :body
end
