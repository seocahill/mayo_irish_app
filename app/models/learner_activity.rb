# What each learner has been doing, for the admin Learners page. Every figure is
# one grouped query across all learners, so the page stays a handful of queries
# however many people sign up.
class LearnerActivity
  Row = Data.define(:user, :last_active_at, :answers, :clips, :minutes_spoken, :lessons_started)

  def initialize(users, since: Time.current.beginning_of_week)
    @users = users
    @since = since
  end

  # Most recently active first; those yet to do anything last.
  def rows
    @users.map { |user| row_for(user) }.sort_by { |row| row.last_active_at.to_i }.reverse
  end

  private

  def row_for(user)
    Row.new(user: user,
            last_active_at: last_active[user.id],
            answers: answers.fetch(user.id, 0),
            clips: clips.fetch(user.id, 0),
            minutes_spoken: seconds_spoken.fetch(user.id, 0).fdiv(60).round,
            lessons_started: lessons_started.fetch(user.id, 0))
  end

  def answers = @answers ||= ReviewLog.where(answered_at: @since..).group(:user_id).count

  def clips = @clips ||= Listen.where(created_at: @since..).group(:user_id).count

  def seconds_spoken
    @seconds_spoken ||= spoken_turns.where(created_at: @since..).group("chat_sessions.user_id").sum(:spoken_seconds)
  end

  def lessons_started
    @lessons_started ||= QuizReview.joins(:quiz_question).group(:user_id).distinct.count("quiz_questions.lesson_id")
  end

  # The latest of anything a learner has done, signing in included.
  def last_active
    @last_active ||= [
      Session.group(:user_id).maximum(:created_at),
      ReviewLog.group(:user_id).maximum(:answered_at),
      Listen.group(:user_id).maximum(:created_at),
      ListeningTime.group(:user_id).maximum(:updated_at),
      spoken_turns.group("chat_sessions.user_id").maximum(:created_at)
    ].reduce { |latest, times| latest.merge(times) { |_, a, b| [ a, b ].max } }
  end

  def spoken_turns = ChatMessage.where(role: "user").where.not(spoken_seconds: nil).joins(:chat_session)
end
