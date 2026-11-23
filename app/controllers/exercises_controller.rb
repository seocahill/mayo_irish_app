# Editors see a lesson's exercises in the lesson editor and write each one's
# answer in Mayo Irish. Every edit is in the lesson's history and can be undone.
class ExercisesController < ApplicationController
  before_action :require_admin
  before_action :set_exercise

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to edit_lesson_path(@exercise.lesson, anchor: "exercises")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_exercise
    @exercise = Exercise.find(params[:id])
  end

  def exercise_params
    params.require(:exercise).permit(:prompt, :answer)
  end
end
