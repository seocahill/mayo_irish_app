# Who has signed up and what they've been doing, for admins.
class LearnersController < ApplicationController
  before_action :require_admin

  def index
    @invitations = Invitation.open.order(created_at: :desc)
    @pending = User.pending_approval.order(created_at: :desc)
    @activity = LearnerActivity.new(User.where(approved: true))
  end

  def show
    @learner = User.find(params[:id])
    @weeks = LearnerWeeks.new(@learner).weeks
    @lessons = lesson_progress
    @spoken_minutes = SpokenTime.new(@learner).minutes
    @listening_minutes = ListeningTime.minutes_for(@learner)
  end

  private

  # The lessons the learner has answered questions in, with how many words they know.
  def lesson_progress
    started = @learner.quiz_reviews.joins(:quiz_question).select("quiz_questions.lesson_id")
    known = Lesson.known_word_counts_for(@learner)
    totals = VocabularyItem.group(:lesson_id).count
    Lesson.ordered.where(id: started).index_with do |lesson|
      LessonProgress.new(known: known.fetch(lesson.id, 0), total: totals.fetch(lesson.id, 0))
    end
  end
end
