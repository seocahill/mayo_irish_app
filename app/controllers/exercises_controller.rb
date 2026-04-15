class ExercisesController < ApplicationController
  before_action :require_admin
  before_action :set_exercise

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to edit_lesson_path(@exercise.lesson)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_exercise
    @exercise = Exercise.find(params[:id])
  end

  def exercise_params
    params.require(:exercise).permit(:number, :prompt, :answer)
  end
end
