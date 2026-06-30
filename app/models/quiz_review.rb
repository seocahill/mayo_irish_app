class QuizReview < ApplicationRecord
  # Leitner box system: a correct answer promotes an item to the next box (longer
  # interval before it resurfaces); a wrong answer drops it back to box 1.
  INTERVALS = { 1 => 0, 2 => 1, 3 => 3, 4 => 7, 5 => 21 }.freeze
  MAX_BOX   = INTERVALS.keys.max
  KNOWN_BOX = 2 # one correct answer (box 1 -> 2) means "known"; a lapse drops below this

  belongs_to :user
  belongs_to :quiz_question

  validates :box, inclusion: { in: INTERVALS.keys }

  scope :known, -> { where(box: KNOWN_BOX..) }
  scope :due,   ->(time = Time.current) { where(due_at: ..time) }

  def known?
    box >= KNOWN_BOX
  end

  # Apply an answer outcome and reschedule the next review.
  def record_answer(correct:)
    if correct
      self.box = [ box + 1, MAX_BOX ].min
      self.times_correct += 1
    else
      self.box = 1
      self.times_wrong += 1
    end

    self.last_reviewed_at = Time.current
    self.due_at = Time.current + INTERVALS.fetch(box).days
    save!
  end
end
