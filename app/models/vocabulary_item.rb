class VocabularyItem < ApplicationRecord
  belongs_to :lesson
  has_one_attached :audio
  has_many :quiz_questions, as: :source, dependent: :destroy

  validates :irish, presence: true
  validates :english, presence: true

  GENDERS = { 'm' => 'Masc.', 'f' => 'Fem.' }.freeze

  scope :ordered, -> { order(:position) }

  def gender_label
    GENDERS[gender] || ''
  end
end
