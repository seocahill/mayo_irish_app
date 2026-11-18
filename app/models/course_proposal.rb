# A suggestion for the course from the designer agent or a contributor.
# Proposals are only ever read and decided on by people; see
# docs/product/COURSE_DESIGNER.md.
class CourseProposal < ApplicationRecord
  KINDS = %w[new_lesson revise_lesson merge retire cross_reference recording_match
             reorder gap dialect_question extraction_request idea].freeze
  STATUSES = %w[captured grounded proposed discussing accepted applied edited dismissed deferred].freeze
  OPEN_STATUSES = %w[captured grounded proposed discussing].freeze

  validates :title, presence: true
  validates :raw_text, length: { maximum: 2000 }
  validates :origin, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  TITLE_LENGTH = 80

  # An idea captured in someone's own words. The words are kept verbatim in
  # raw_text; the title is only a short label made from them.
  def self.capture(text, origin:)
    text = text.to_s
    new(kind: "idea", status: "captured", origin: origin, raw_text: text,
        title: text.squish.truncate(TITLE_LENGTH, separator: " "))
  end

  # What a person can do with a proposal from the list. Each only changes the
  # proposal's own status; nothing here touches a lesson.
  DECISIONS = { "discuss" => "discussing", "defer" => "deferred", "dismiss" => "dismissed",
                "reopen" => "proposed" }.freeze

  PARKED_STATUSES = %w[dismissed deferred].freeze

  # Decisions allowed now: open ones can be discussed, deferred or dismissed,
  # parked ones reopened. Accepted, applied and edited ones are left alone.
  def decisions
    if status.in?(OPEN_STATUSES) then %w[discuss defer dismiss]
    elsif status.in?(PARKED_STATUSES) then %w[reopen]
    else []
    end
  end

  def decide!(decision, by:)
    return false unless decisions.include?(decision)
    if decision == "reopen"
      update!(status: DECISIONS.fetch(decision), decided_by: nil, decided_at: nil)
    else
      update!(status: DECISIONS.fetch(decision), decided_by: by, decided_at: Time.current)
    end
  end

  scope :pending, -> { where(status: OPEN_STATUSES) }
  scope :ordered, -> { order(priority: :desc, created_at: :desc) }
end
