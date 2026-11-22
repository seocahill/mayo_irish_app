# The learner's own last eight weeks of practice, so they can look back and see
# that they are getting somewhere. Read-only; quiet weeks are shown plainly.
class WeeksController < ApplicationController
  def show
    @weeks = LearnerWeeks.new(current_user).weeks
  end
end
