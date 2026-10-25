class ChatSession < ApplicationRecord
  belongs_to :lesson
  belongs_to :user, optional: true
  has_many :chat_messages, -> { order(:id) }, dependent: :destroy

  # A tutor chat quizzes in English; a conversation (the comhrá) talks in Irish.
  enum :kind, { tutor: "tutor", conversation: "conversation" }, validate: true
end
