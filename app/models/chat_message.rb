class ChatMessage < ApplicationRecord
  # How long a spoken turn can be: the recogniser takes up to 30 seconds.
  SPOKEN_SECONDS = 1..30

  belongs_to :chat_session
  validates :role, inclusion: { in: %w[user assistant] }
  validates :content, presence: true
  validates :spoken_seconds, numericality: { only_integer: true, in: SPOKEN_SECONDS }, allow_nil: true

  scope :flagged, -> { where.not(flagged_at: nil) }
  scope :spoken_by, ->(user) { where(role: "user").where.not(spoken_seconds: nil).joins(:chat_session).merge(user.chat_sessions) }
  scope :conversation_replies_to, ->(user) { where(role: "assistant").joins(:chat_session).merge(user.chat_sessions.conversation) }

  # Comhrá replies a learner thinks have wrong Irish, for an editor to check.
  def flagged? = flagged_at.present?

  def flag!
    update!(flagged_at: Time.current) unless flagged?
  end

  def dismiss_flag!
    update!(flagged_at: nil)
  end
end
