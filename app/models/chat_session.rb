class ChatSession < ApplicationRecord
  belongs_to :lesson
  has_many :chat_messages, -> { order(:id) }, dependent: :destroy
end
