# How long a learner has spoken Irish: the length of their spoken comhrá turns,
# plus the time they spent recording themselves (Say it, shadowing, the word
# list), which is kept per day as SpeakingDay.
class SpokenTime
  def initialize(user)
    @turns = ChatMessage.spoken_by(user)
    @days = user.speaking_days
  end

  def minutes = in_minutes(@turns.sum(:spoken_seconds) + @days.sum(:seconds))

  def minutes_this_week
    starts = Time.current.beginning_of_week
    in_minutes(@turns.where(created_at: starts..).sum(:spoken_seconds) + @days.where(day: starts.to_date..).sum(:seconds))
  end

  private

  def in_minutes(seconds) = seconds.fdiv(60).round
end
