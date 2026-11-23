class Exercise < ApplicationRecord
  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(e) { e.lesson_id },
                            label: ->(e) { I18n.t("exercises.label", number: e.number) },
                            only: %i[prompt answer]

  belongs_to :lesson
  has_many :phrases, as: :source, dependent: :destroy

  validates :number, presence: true
  validates :prompt, presence: true

  normalizes :answer, with: ->(answer) { answer.strip.presence }

  scope :answered, -> { where.not(answer: [ nil, "" ]) }

  searchable title: ->(e) { "Exercise #{e.number}" },
             body: ->(e) { [e.prompt, e.answer] },
             lesson_number: ->(e) { e.lesson&.number }
end
