class GrammarRule < ApplicationRecord
  belongs_to :lesson
  has_many :grammar_sections, -> { order(:position) }, dependent: :destroy
  has_many :phrases, as: :source, dependent: :destroy

  validates :number, presence: true
  validates :title, presence: true

  has_rich_text :body
end
