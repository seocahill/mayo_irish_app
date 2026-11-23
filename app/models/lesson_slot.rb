# A job on a draft lesson: Irish the lesson still needs, described in English
# ("3 to 5 example sentences for the conditional after dá, Erris preferred").
# A slot is the honest alternative to placeholder Irish in a lesson: it holds
# only the English spec, and a lesson with open slots can't be published until
# each is filled or removed. Removing a slot keeps it, marked removed.
# See docs/product/COURSE_DESIGNER.md §5.
class LessonSlot < ApplicationRecord
  SLOT_TYPES = %w[example_sentences vocabulary phrases dialogue listening_clip grammar_table].freeze
  STATUSES = %w[open removed].freeze
  SPEC_LENGTH = 1000

  belongs_to :lesson

  validates :slot_type, inclusion: { in: SLOT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :spec, presence: true, length: { maximum: SPEC_LENGTH }

  scope :open, -> { where(status: "open") }
  scope :oldest_first, -> { order(:created_at, :id) }

  def open? = status == "open"

  # Returns false if the slot was already removed.
  def remove!(by:)
    return false unless open?
    update!(status: "removed", removed_by: by, removed_at: Time.current)
  end
end
