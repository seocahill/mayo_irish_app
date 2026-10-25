class VocabularyItem < ApplicationRecord
  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(v) { v.lesson_id },
                            label: ->(v) { v.irish }

  belongs_to :lesson
  has_one_attached :audio
  has_many :quiz_questions, as: :source, dependent: :destroy

  validates :irish, presence: true
  validates :english, presence: true

  searchable title: ->(v) { "#{v.irish} — #{v.english}" },
             body: ->(v) { [v.irish, v.english, v.phonetic, v.plural, v.notes] },
             lesson_number: ->(v) { v.lesson&.number }

  GENDERS = { 'm' => 'Masc.', 'f' => 'Fem.' }.freeze

  scope :ordered, -> { order(:position) }

  def gender_label
    GENDERS[gender] || ''
  end
end
