# Admin list of course proposals, and a box to capture an idea in one's own words.
class CourseProposalsController < ApplicationController
  before_action :require_admin

  def index
    @proposals = CourseProposal.ordered.includes(:proposal_comments)
  end

  def update
    proposal = CourseProposal.find(params[:id])
    if CourseProposal::DECISIONS.key?(params[:decision])
      if proposal.decide!(params[:decision], by: current_user.email_address.split("@").first)
        redirect_to course_proposals_path, notice: t(".#{params[:decision]}")
      else
        redirect_to course_proposals_path, alert: t(".unknown")
      end
    else
      redirect_to course_proposals_path, alert: t(".unknown")
    end
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
