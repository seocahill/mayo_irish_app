# A single-use link an admin hands to someone so they can register. Whoever
# registers through it is let straight in, as the admin has already vouched
# for them.
class Invitation < ApplicationRecord
  LIFETIME = 7.days

  belongs_to :inviter, class_name: "User"
  belongs_to :user, optional: true

  has_secure_token :token
  attribute :expires_at, default: -> { LIFETIME.from_now }

  scope :open, -> { where(accepted_at: nil).where(expires_at: Time.current..) }

  def accept(user)
    user.approved = true
    transaction { user.save && update!(user:, accepted_at: Time.current) }
  end
end
