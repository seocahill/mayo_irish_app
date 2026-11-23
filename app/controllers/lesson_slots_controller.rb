# Admins add slots to a draft lesson (Irish it still needs, described in
# English) and remove them. Removing marks a slot removed; nothing is deleted.
class LessonSlotsController < ApplicationController
  before_action :require_admin

  def create
    lesson = Lesson.find_by!(number: params[:lesson_id])
    return redirect_to(edit_lesson_path(lesson, anchor: "slots"), alert: t(".published")) if lesson.published?

    slot = lesson.lesson_slots.new(slot_params.merge(created_by: current_user.email_address))
    if slot.save
      redirect_to edit_lesson_path(lesson, anchor: "slots"), notice: t(".added")
    else
      redirect_to edit_lesson_path(lesson, anchor: "slots"), alert: slot.errors.full_messages.to_sentence
    end
  end

  def destroy
    slot = LessonSlot.find(params[:id])
    slot.remove!(by: current_user.email_address)
    redirect_to edit_lesson_path(slot.lesson, anchor: "slots"), notice: t(".removed")
  end

  private

  def slot_params
    params.require(:lesson_slot).permit(:slot_type, :spec)
  end
end
