class VocabularyItem < ApplicationRecord
  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(v) { v.lesson_id },
                            label: ->(v) { v.irish }

  belongs_to :lesson
  has_one_attached :audio
  has_many :quiz_questions, as: :source, dependent: :destroy
  has_many :recording_suggestions, dependent: :destroy

  validates :irish, presence: true
  validates :english, presence: true

  searchable title: ->(v) { "#{v.irish} — #{v.english}" },
             body: ->(v) { [v.irish, v.english, v.phonetic, v.plural, v.notes] },
             lesson_number: ->(v) { v.lesson&.number }

  GENDERS = { 'm' => 'Masc.', 'f' => 'Fem.' }.freeze

  scope :ordered, -> { order(:position) }
  # Said by a speaker: an uploaded recording or an approved one from Abairt.
  scope :with_recording, -> { left_joins(:audio_attachment).where("vocabulary_items.audio_url <> '' OR active_storage_attachments.id IS NOT NULL") }

  def gender_label
    GENDERS[gender] || ''
  end
end
