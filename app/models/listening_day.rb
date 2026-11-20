# Seconds a learner spent listening to Abairt recordings on one day, kept so
# Today can show an honest "this week" figure (the lifetime total in
# ListeningTime cannot say when the listening happened).
class ListeningDay < ApplicationRecord
  belongs_to :user

  validates :day, presence: true, uniqueness: { scope: :user_id }
  validates :seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.add(user, seconds, on: Time.zone.today)
    return if seconds <= 0

    connection.execute(sanitize_sql_array([
      "INSERT INTO listening_days (user_id, day, seconds, created_at, updated_at) VALUES (?, ?, ?, ?, ?) " \
      "ON CONFLICT (user_id, day) DO UPDATE SET seconds = seconds + excluded.seconds, updated_at = excluded.updated_at",
      user.id, on, seconds, Time.current, Time.current
    ]))
  end

  def self.minutes_this_week(user)
    where(user: user, day: Time.zone.today.beginning_of_week..).sum(:seconds).fdiv(60).round
  end
end
