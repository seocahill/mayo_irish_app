# How long a learner has spoken Irish in the comhrá, from the length of their
# recorded turns.
class SpokenTime
  def initialize(user)
    @turns = ChatMessage.spoken_by(user)
  end

  def minutes = in_minutes(@turns.sum(:spoken_seconds))

  def minutes_this_week = in_minutes(@turns.where(created_at: Time.current.beginning_of_week..).sum(:spoken_seconds))

  private

  def in_minutes(seconds) = seconds.fdiv(60).round
end
