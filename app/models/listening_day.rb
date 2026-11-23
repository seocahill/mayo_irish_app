# Seconds a learner spent listening on one day, kept so Today can show an
# honest "this week" figure (the lifetime total in ListeningTime cannot say
# when the listening happened). `seconds` is all of it: whole Abairt
# recordings and short clips; `clip_seconds` is the part that was clips, which
# ListeningTime doesn't hold, so the lifetime total can add it.
class ListeningDay < ApplicationRecord
  belongs_to :user

  validates :day, presence: true, uniqueness: { scope: :user_id }
  validates :seconds, :clip_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.add(user, seconds, on: Time.zone.today, clip: false)
    return if seconds <= 0

    clip_seconds = clip ? seconds : 0
    connection.execute(sanitize_sql_array([
      "INSERT INTO listening_days (user_id, day, seconds, clip_seconds, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?) " \
      "ON CONFLICT (user_id, day) DO UPDATE SET seconds = seconds + excluded.seconds, " \
      "clip_seconds = clip_seconds + excluded.clip_seconds, updated_at = excluded.updated_at",
      user.id, on, seconds, clip_seconds, Time.current, Time.current
    ]))
  end

  # Time spent playing a listening clip, as reported by its page.
  def self.add_clip(user, seconds)
    add(user, seconds.to_s.to_i.clamp(0, ListeningTime::MAX_REPORT), clip: true)
  end

  def self.minutes_this_week(user)
    where(user: user, day: Time.zone.today.beginning_of_week..).sum(:seconds).fdiv(60).round
  end
end
