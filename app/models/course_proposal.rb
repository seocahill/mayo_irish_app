# A suggestion for the course from the designer agent or a contributor.
# Proposals are only ever read and decided on by people; see
# docs/product/COURSE_DESIGNER.md.
class CourseProposal < ApplicationRecord
  KINDS = %w[new_lesson revise_lesson merge retire cross_reference recording_match
             reorder gap dialect_question extraction_request idea].freeze
  STATUSES = %w[captured grounded proposed discussing accepted applied edited dismissed deferred].freeze
  OPEN_STATUSES = %w[captured grounded proposed discussing].freeze

  has_many :proposal_comments, -> { order(:created_at, :id) }, dependent: :destroy
  has_many :proposal_evidence, -> { order(:created_at, :id) }, class_name: "ProposalEvidence", dependent: :destroy

  validates :title, presence: true
  validates :raw_text, length: { maximum: 2000 }
  validates :origin, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  TITLE_LENGTH = 80
  SUMMARY_LENGTH = 160
  # The designer agent's own proposals; any other origin is a person.
  AGENT_ORIGIN = "designer"

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

  # Open proposals in the order a person should decide them: people's own ideas
  # before the agent's (COURSE_DESIGNER.md §7), then higher priority, then the
  # one that has waited longest.
  scope :review_order, -> {
    pending.order(Arel::Nodes::Case.new(arel_table[:origin]).when(AGENT_ORIGIN).then(1).else(0))
           .order(priority: :desc, created_at: :asc, id: :asc)
  }

  # One line saying what the proposal is about: the reasoning, the outline or
  # the original words, squeezed onto a line. Nil when it would only repeat the
  # title (a captured idea's title is made from its words).
  def summary
    line = [ rationale, outline, raw_text ].find(&:present?).to_s.squish.truncate(SUMMARY_LENGTH, separator: " ")
    line.presence unless line == title.to_s.squish
  end
end
