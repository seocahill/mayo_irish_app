# Admin list of course proposals, and a box to capture an idea in one's own words.
class CourseProposalsController < ApplicationController
  before_action :require_admin

  def index
    @proposals = CourseProposal.ordered
  end

  def create
    proposal = CourseProposal.capture(params[:raw_text], origin: current_user.email_address.split("@").first)
    if proposal.save
      redirect_to course_proposals_path, notice: t(".saved")
    else
      redirect_to course_proposals_path, alert: proposal.errors.include?(:raw_text) ? t(".too_long") : t(".blank")
    end
  end
end
