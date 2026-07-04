class Exercise < ApplicationRecord
  include Searchable

  belongs_to :lesson
  has_many :phrases, as: :source, dependent: :destroy

  validates :number, presence: true
  validates :prompt, presence: true

  searchable title: ->(e) { "Exercise #{e.number}" },
             body: ->(e) { [e.prompt, e.answer] },
             lesson_number: ->(e) { e.lesson&.number }
end
