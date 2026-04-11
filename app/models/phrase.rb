class Phrase < ApplicationRecord
  belongs_to :lesson
  belongs_to :source, polymorphic: true, optional: true

  validates :irish, presence: true
end
