class GrammarRule < ApplicationRecord
  include Searchable

  belongs_to :lesson
  has_many :grammar_sections, -> { order(:position) }, dependent: :destroy
  has_many :phrases, as: :source, dependent: :destroy

  validates :number, presence: true
  validates :title, presence: true

  has_rich_text :body

  searchable title: ->(r) { r.title },
             body: ->(r) { [r.title, r.body&.to_plain_text] },
             lesson_number: ->(r) { r.lesson&.number }
end
