class ChatMessage < ApplicationRecord
  belongs_to :chat_session
  validates :role, inclusion: { in: %w[user assistant] }
  validates :content, presence: true
end
