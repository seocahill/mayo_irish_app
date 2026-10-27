# A learner having listened to a clip, and whether they made it out.
class Listen < ApplicationRecord
  belongs_to :user
  belongs_to :listening_clip

  validates :understood, inclusion: { in: [ true, false ] }
  validates :listening_clip_id, uniqueness: { scope: :user_id }

  scope :today, -> { where(created_at: Time.current.all_day) }
end
