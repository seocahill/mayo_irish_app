class ChatMessage < ApplicationRecord
  belongs_to :chat_session
  validates :role, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  scope :flagged, -> { where.not(flagged_at: nil) }

  # Comhrá replies a learner thinks have wrong Irish, for an editor to check.
  def flagged? = flagged_at.present?

  def flag!
    update!(flagged_at: Time.current) unless flagged?
  end

  def dismiss_flag!
    update!(flagged_at: nil)
  end
end
