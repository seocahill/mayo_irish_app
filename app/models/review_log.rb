# Append-only history of quiz answers. Survives the question being pruned.
class ReviewLog < ApplicationRecord
  belongs_to :user
  belongs_to :quiz_question, optional: true

  validates :prompt, :answered_at, presence: true
  validates :correct, inclusion: { in: [ true, false ] }
  validates :box_before, :box_after, inclusion: { in: QuizReview::INTERVALS.keys }
end
