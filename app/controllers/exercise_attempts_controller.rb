# "Put it into Irish" on a lesson's exercises: lines up what the learner wrote
# against the answer an editor wrote for that exercise (see Dictation). Nothing
# is stored, graded or generated; only answered exercises in lessons the
# learner can see are offered.
class ExerciseAttemptsController < ApplicationController
  def create
    @exercise = Exercise.answered.where(lesson: Lesson.visible_to(current_user)).find(params[:exercise_id])
    @comparison = Dictation.new(@exercise.answer, params[:attempt].to_s)
  end
end
