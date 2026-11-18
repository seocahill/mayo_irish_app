# One message in the discussion on a course proposal, so feedback is data.
class ProposalComment < ApplicationRecord
  belongs_to :course_proposal
  validates :author, presence: true
  validates :body, presence: true, length: { maximum: 2000 }
end
