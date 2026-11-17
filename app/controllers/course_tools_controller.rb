# One page linking the admin-only course-design tools.
class CourseToolsController < ApplicationController
  before_action :require_admin

  TOOLS = {
    gaps: :vocabulary_gaps_path,
    substitutions: :dialect_substitutions_path,
    usage: :usage_path,
    learners: :learners_path,
    flagged_replies: :flagged_replies_path
  }.freeze

  def show
    @tools = TOOLS
  end
end
