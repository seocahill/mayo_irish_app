# A real Mayo recording from Abairt suggested for a vocabulary word. Learners
# only hear it once an editor approves it, which makes it the word's recording,
# credited to the speaker.
class RecordingSuggestion < ApplicationRecord
  PER_WORD = 3

  belongs_to :vocabulary_item
  belongs_to :reviewed_by, class_name: "User", optional: true

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, validate: true

  validates :abairt_entry_id, uniqueness: { scope: :vocabulary_item_id }
  validates :irish, :audio_url, presence: true

  # Ones the recogniser confirmed first, then in the order they were ranked.
  scope :best_first, -> { order(check_passed: :desc, id: :asc) }

  # Makes this the word's recording; the word's other suggestions are set aside.
  def approve!(by:)
    transaction do
      vocabulary_item.update!(audio_url: audio_url, audio_credit: speaker_name)
      vocabulary_item.recording_suggestions.pending.where.not(id: id).update_all(status: "rejected", reviewed_by_id: by.id, reviewed_at: Time.current)
      update!(status: "approved", reviewed_by: by, reviewed_at: Time.current)
    end
  end

  # Approves the best checked suggestion of each of these words that has none
  # approved yet. Returns how many it approved.
  def self.approve_checked!(items, by:)
    pending.where(check_passed: true, vocabulary_item: items)
           .where.not(vocabulary_item_id: approved.select(:vocabulary_item_id))
           .includes(:vocabulary_item).order(:id)
           .group_by(&:vocabulary_item_id).each_value.count { |suggestions| suggestions.first.approve!(by: by) }
  end

  def reject!(by:)
    update!(status: "rejected", reviewed_by: by, reviewed_at: Time.current)
  end
end
