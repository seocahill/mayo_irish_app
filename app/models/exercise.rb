class Exercise < ApplicationRecord
  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(e) { e.lesson_id },
                            label: ->(e) { I18n.t("exercises.label", number: e.number) }

  belongs_to :lesson
  has_many :phrases, as: :source, dependent: :destroy
  # Its card in the daily review (see QuizQuestion.sync_exercises).
  has_many :quiz_questions, as: :source, dependent: :destroy

  validates :number, presence: true
  validates :prompt, presence: true

  normalizes :answer, with: ->(answer) { answer.strip.presence }

  # Answers are normalized to nil when blank, but a row written another way
  # (update_column, raw SQL) could still hold only spaces.
  scope :answered, -> { where.not(answer: nil).where("TRIM(answer) <> ''") }

  # An edited answer or prompt reaches the review card straight away, so a
  # learner never sees an answer the editors have since changed.
  after_update_commit :refresh_quiz_questions, if: -> { answer.present? && (saved_change_to_answer? || saved_change_to_prompt?) }

  searchable title: ->(e) { "Exercise #{e.number}" },
             body: ->(e) { [e.prompt, e.answer] },
             lesson_number: ->(e) { e.lesson&.number }

  private

  def refresh_quiz_questions
    # A fresh query: the association may have been loaded (and cached) before the card existed.
    QuizQuestion.where(source: self).find_each { |question| question.update!(prompt: prompt, answer: answer) }
  end
end
