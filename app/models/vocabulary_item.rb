class VocabularyItem < ApplicationRecord
  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(v) { v.lesson_id },
                            label: ->(v) { v.irish }

  belongs_to :lesson
  has_one_attached :audio
  has_many :quiz_questions, as: :source, dependent: :destroy
  has_many :recording_suggestions, dependent: :destroy
  has_many :listening_clips, dependent: :destroy
  has_many :form_suggestion_dismissals, dependent: :destroy

  validates :irish, presence: true
  validates :english, presence: true

  searchable title: ->(v) { "#{v.irish} — #{v.english}" },
             body: ->(v) { [v.irish, v.english, v.phonetic, v.plural, v.genitive, v.notes] },
             lesson_number: ->(v) { v.lesson&.number }

  PARTS_OF_SPEECH = %w[noun verb adjective adverb other].freeze
  normalizes :part_of_speech, with: ->(v) { v.presence }
  validates :part_of_speech, inclusion: { in: PARTS_OF_SPEECH }, allow_nil: true
  normalizes :source, with: ->(v) { v.to_s.strip.presence }
  validates :source, length: { maximum: 200 }

  GENDERS = { 'm' => 'Masc.', 'f' => 'Fem.' }.freeze

  # An editor changing an accepted form by hand means it no longer comes from that entry.
  before_save do
    self.plural_source_entry_id = nil if plural_changed? && !plural_source_entry_id_changed?
    self.genitive_source_entry_id = nil if genitive_changed? && !genitive_source_entry_id_changed?
  end

  # Keep the plural, genitive and gender review cards in step with an editor's
  # change: a changed form updates its card, a removed one removes it.
  after_update_commit :refresh_noun_form_cards,
                      if: -> { saved_change_to_plural? || saved_change_to_genitive? || saved_change_to_gender? || saved_change_to_irish? }

  scope :unclassified, -> { where(part_of_speech: nil) }
  scope :ordered, -> { order(:position) }
  # Said by a speaker: an uploaded recording or an approved one from Abairt.
  scope :with_recording, -> { left_joins(:audio_attachment).where("vocabulary_items.audio_url <> '' OR active_storage_attachments.id IS NOT NULL") }

  def refresh_noun_form_cards
    QuizQuestion.sync_noun_forms([ self ])
    blank = QuizQuestion::FORM_DIRECTIONS.select { |direction| public_send(direction).blank? }
    blank << QuizQuestion::GENDER unless QuizQuestion::GENDERS.include?(gender)
    quiz_questions.where(direction: blank).destroy_all if blank.any?
  end

  def gender_label
    GENDERS[gender] || ''
  end
end
