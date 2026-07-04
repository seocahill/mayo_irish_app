class Phrase < ApplicationRecord
  include Searchable

  belongs_to :lesson
  belongs_to :source, polymorphic: true, optional: true

  validates :irish, presence: true

  searchable title: ->(p) { p.irish },
             body: ->(p) { [p.irish, p.english] },
             lesson_number: ->(p) { p.lesson&.number }
end
