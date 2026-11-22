# Seconds a learner spent recording themselves on one day (Say it cards,
# shadowing a listening clip, the lesson word list), so it counts towards
# minutes spoken. Only the length is kept: the recording never leaves the phone.
class SpeakingDay < ApplicationRecord
  # A recording longer than this is a recorder left running, not speech.
  MAX_RECORDING = 30

  belongs_to :user

  validates :day, presence: true, uniqueness: { scope: :user_id }
  validates :seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.add(user, seconds, on: Time.zone.today)
    seconds = seconds.to_i.clamp(0, MAX_RECORDING)
    return if seconds.zero?

    connection.execute(sanitize_sql_array([
      "INSERT INTO speaking_days (user_id, day, seconds, created_at, updated_at) VALUES (?, ?, ?, ?, ?) " \
      "ON CONFLICT (user_id, day) DO UPDATE SET seconds = seconds + excluded.seconds, updated_at = excluded.updated_at",
      user.id, on, seconds, Time.current, Time.current
    ]))
  end
end
