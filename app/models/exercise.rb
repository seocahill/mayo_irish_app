class Exercise < ApplicationRecord
  belongs_to :lesson
  has_many :phrases, as: :source, dependent: :destroy

  validates :number, presence: true
  validates :prompt, presence: true
end
