# One page linking the admin-only course-design tools.
class CourseToolsController < ApplicationController
  before_action :require_admin

  TOOLS = {
    gaps: :vocabulary_gaps_path,
    where_taught: :where_taught_path,
    hard_words: :hard_words_path,
    proposals: :course_proposals_path,
    substitutions: :dialect_substitutions_path,
    usage: :usage_path,
    learners: :learners_path,
    flagged_replies: :flagged_replies_path
  }.freeze

  def show
    @tools = TOOLS
  end
end
