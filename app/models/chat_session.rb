class ChatSession < ApplicationRecord
  belongs_to :lesson
  belongs_to :user, optional: true
  has_many :chat_messages, -> { order(:id) }, dependent: :destroy
end
