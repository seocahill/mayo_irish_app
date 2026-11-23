# How long a learner has listened to a whole Abairt recording, as reported by
# the page while it plays (see the transcript controller).
class ListeningTime < ApplicationRecord
  # The page reports about every 30 seconds; anything much longer isn't real listening.
  MAX_REPORT = 60

  belongs_to :user

  validates :abairt_recording_id, presence: true, uniqueness: { scope: :user_id }
  validates :seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent, -> { where(updated_at: 1.week.ago..) }

  # Everything the learner has listened to: whole recordings, and the clips
  # counted day by day in ListeningDay.
  def self.minutes_for(user)
    (where(user: user).sum(:seconds) + ListeningDay.where(user: user).sum(:clip_seconds)).fdiv(60).round
  end

  def add(seconds)
    seconds = seconds.to_i.clamp(0, MAX_REPORT)
    transaction do
      increment!(:seconds, seconds)
      ListeningDay.add(user, seconds)
    end
  end
end
