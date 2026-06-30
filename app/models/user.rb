class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy
  has_many :section_progresses, dependent: :destroy
  has_many :quiz_reviews, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :pending_approval, -> { where(approved: false) }

  def approved?
    approved
  end

  def admin?
    admin
  end
end
