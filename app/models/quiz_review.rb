class QuizReview < ApplicationRecord
  # Leitner box system: a correct answer promotes an item to the next box (longer
  # interval before it resurfaces); a wrong answer drops it back to box 1.
  INTERVALS = { 1 => 0, 2 => 1, 3 => 3, 4 => 7, 5 => 21 }.freeze
  MAX_BOX   = INTERVALS.keys.max
  KNOWN_BOX = 2 # legacy Leitner threshold, kept so the box column stays meaningful

  # Scheduling is FSRS (target retention 90%): stability is the number of days
  # until predicted recall falls to 90%. A word is "known" once it is in the
  # review state and that is at least a week, so one lucky answer isn't enough.
  KNOWN_STABILITY = 7.0
  REVIEW_STATE = Fsrs::State::REVIEW
  RATINGS = { again: Fsrs::Rating::AGAIN, hard: Fsrs::Rating::HARD,
              good: Fsrs::Rating::GOOD, easy: Fsrs::Rating::EASY }.freeze
  SCHEDULER = Fsrs::Scheduler.new.tap { |s| s.p.request_retention = 0.9 }.freeze

  belongs_to :user
  belongs_to :quiz_question

  validates :box, inclusion: { in: INTERVALS.keys }

  scope :known, -> { where(fsrs_state: REVIEW_STATE, stability: KNOWN_STABILITY..) }
  scope :due,   ->(time = Time.current) { where(due_at: ..time) }

  def known?
    fsrs_state == REVIEW_STATE && stability >= KNOWN_STABILITY
  end

  # Counts for the line under the review button: still to do today (including
  # anything overdue), due tomorrow, and due in the following days.
  def self.forecast_for(user, now: Time.current)
    scope = where(user: user)
    tomorrow = (now.to_date + 1).all_day
    later = (now.to_date + 2).beginning_of_day..(now.to_date + 7).end_of_day
    { today: scope.due(now.end_of_day).count,
      tomorrow: scope.where(due_at: tomorrow).count,
      week: scope.where(due_at: tomorrow.begin..later.end).count }
  end

  # Apply an answer outcome (a rating of :again, :hard, :good or :easy, or just
  # correct/wrong from multiple choice), reschedule the next review with FSRS,
  # and log the answer. The Leitner box is still updated alongside.
  def record_answer(correct:, rating: nil)
    rating ||= correct ? :good : :again
    correct = rating != :again
    box_before = box
    now = Time.current

    info = SCHEDULER.repeat(fsrs_card, now.utc.to_datetime).fetch(RATINGS.fetch(rating))
    card = info.card
    self.stability = card.stability.to_f
    self.difficulty = card.difficulty.to_f
    self.fsrs_state = card.state
    self.due_at = card.due.to_time

    if correct
      self.box = [ box + 1, MAX_BOX ].min
      self.times_correct += 1
    else
      self.box = 1
      self.times_wrong += 1
    end
    self.last_reviewed_at = now

    transaction do
      save!
      ReviewLog.create!(user: user, quiz_question: quiz_question, prompt: quiz_question.prompt,
                        correct: correct, box_before: box_before, box_after: box,
                        answered_at: last_reviewed_at)
    end
  end

  private

  def fsrs_card
    card = Fsrs::Card.new
    card.state = fsrs_state
    card.stability = stability
    card.difficulty = difficulty
    # A row without a review time (never answered) is a new card.
    if last_reviewed_at
      card.last_review = last_reviewed_at.utc.to_datetime
      card.due = (due_at || last_reviewed_at).utc.to_datetime
    else
      card.state = Fsrs::State::NEW
    end
    card.reps = times_correct + times_wrong
    card.lapses = times_wrong
    card
  end
end
