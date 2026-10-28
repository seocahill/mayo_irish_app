# An admin letting someone who signed up into the beta.
class LearnerApprovalsController < ApplicationController
  before_action :require_admin

  def create
    learner = User.pending_approval.find(params[:learner_id])
    learner.approve!
    redirect_to learners_path, notice: t(".approved", email: learner.email_address)
  end
end
