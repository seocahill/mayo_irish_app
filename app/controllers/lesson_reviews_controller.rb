# Marks a lesson as checked by an admin (or clears that mark). Draft lessons
# that nobody has reviewed show up as "needs review" in the lessons list.
class LessonReviewsController < ApplicationController
  before_action :require_admin
  before_action :set_lesson

  def create
    @lesson.mark_reviewed(by: current_user)
    redirect_to edit_lesson_path(@lesson), notice: t("lesson_reviews.flash.reviewed")
  end

  def destroy
    @lesson.clear_review
    redirect_to edit_lesson_path(@lesson), notice: t("lesson_reviews.flash.cleared")
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:lesson_id])
  end
end
