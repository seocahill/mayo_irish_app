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

  # The vocabulary words this learner has answered wrongly several times lately
  # (either direction counts toward the same word), most missed first.
  # Read-only: it only reads the learner's own answers.
  def self.tricky_words_for(user, except: [])
    visible = Lesson.visible_to(user).select(:id)
    counts = joins(:quiz_question)
             .where(user: user, correct: false, answered_at: TRICKY_DAYS.days.ago..,
                    quiz_questions: { source_type: "VocabularyItem", direction: QuizQuestion::DIRECTIONS, lesson_id: visible })
             .group("quiz_questions.source_id").having("COUNT(*) >= ?", TRICKY_MISSES)
             .order(Arel.sql("COUNT(*) DESC"), "quiz_questions.source_id").count
    ids = counts.keys - Array(except)
    return [] if ids.empty?

    ids = ids.first(TRICKY_LIMIT)
    questions = QuizQuestion.meaning_cards.where(source_id: ids).includes(:source, :lesson)
                            .group_by(&:source_id)
    ids.filter_map { |id| questions[id]&.min_by(&:id) }
  end
end
