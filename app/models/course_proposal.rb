# A suggestion for the course from the designer agent or a contributor.
# Proposals are only ever read and decided on by people; see
# docs/product/COURSE_DESIGNER.md.
class CourseProposal < ApplicationRecord
  KINDS = %w[new_lesson revise_lesson merge retire cross_reference recording_match
             reorder gap dialect_question extraction_request].freeze
  STATUSES = %w[captured grounded proposed discussing accepted applied edited dismissed deferred].freeze
  OPEN_STATUSES = %w[captured grounded proposed discussing].freeze

  validates :title, presence: true
  validates :origin, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :open, -> { where(status: OPEN_STATUSES) }
  scope :ordered, -> { order(priority: :desc, created_at: :desc) }
end
