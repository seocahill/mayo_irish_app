# Admin-only: the exercises learners most often rate Again in review.
class HardExercisesController < ApplicationController
  before_action :require_admin

  def show
    @rows = HardExercises.new.rows
  end
end
