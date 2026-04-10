class VocabularyItem < ApplicationRecord
  belongs_to :lesson

  validates :irish, presence: true
  validates :english, presence: true

  GENDERS = { 'm' => 'Masc.', 'f' => 'Fem.' }.freeze

  scope :ordered, -> { order(:position) }

  def gender_label
    GENDERS[gender] || ''
  end
end
