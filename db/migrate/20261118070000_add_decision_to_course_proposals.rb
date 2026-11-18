class AddDecisionToCourseProposals < ActiveRecord::Migration[8.0]
  def change
    add_column :course_proposals, :decided_by, :string
    add_column :course_proposals, :decided_at, :datetime
  end
end
