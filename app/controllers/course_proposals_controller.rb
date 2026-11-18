# Read-only admin list of course proposals.
class CourseProposalsController < ApplicationController
  before_action :require_admin

  def index
    @proposals = CourseProposal.ordered
  end
end
