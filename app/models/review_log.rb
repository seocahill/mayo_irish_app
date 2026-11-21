# Append-only history of quiz answers. Survives the question being pruned.
class ReviewLog < ApplicationRecord
  belongs_to :user
  belongs_to :quiz_question, optional: true

  validates :prompt, :answered_at, presence: true
  validates :correct, inclusion: { in: [ true, false ] }
  validates :box_before, :box_after, inclusion: { in: QuizReview::INTERVALS.keys }

  TRICKY_DAYS = 30
  TRICKY_MISSES = 3
  TRICKY_LIMIT = 5

  # The vocabulary words this learner has answered wrongly several times lately,
  # most missed first. Read-only: it only reads the learner's own answers.
  def self.tricky_words_for(user)
    ids = where(user: user, correct: false, answered_at: TRICKY_DAYS.days.ago..)
          .where.not(quiz_question_id: nil)
          .group(:quiz_question_id).having("COUNT(*) >= ?", TRICKY_MISSES)
          .order(Arel.sql("COUNT(*) DESC"), :quiz_question_id).pluck(:quiz_question_id)
    return [] if ids.empty?

    visible = Lesson.visible_to(user).select(:id)
    QuizQuestion.where(id: ids, source_type: "VocabularyItem", lesson_id: visible).includes(:source, :lesson)
                .sort_by { |q| ids.index(q.id) }.uniq { |q| q.source_id }.first(TRICKY_LIMIT)
  end
end
