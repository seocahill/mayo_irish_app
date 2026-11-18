# Adds a message to a proposal's discussion. Never touches a lesson.
class ProposalCommentsController < ApplicationController
  before_action :require_admin

  def create
    proposal = CourseProposal.find(params[:course_proposal_id])
    comment = proposal.proposal_comments.build(body: params[:body].to_s.strip,
                                               author: current_user.email_address.split("@").first)
    if comment.save
      redirect_to course_proposals_path(anchor: "proposal-#{proposal.id}"), notice: t(".saved")
    else
      redirect_to course_proposals_path(anchor: "proposal-#{proposal.id}"), alert: t(".invalid")
    end
  end
end
