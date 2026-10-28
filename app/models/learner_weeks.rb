# One learner's activity week by week, newest first, for their admin page.
class LearnerWeeks
  Week = Data.define(:starts_on, :answers, :correct, :clips, :minutes_spoken)

  def initialize(user, weeks: 8)
    @user = user
    @starts = Array.new(weeks) { |n| n.weeks.ago.to_date.beginning_of_week }
  end

  def weeks = @starts.map { |starts_on| week_starting(starts_on) }

  private

  attr_reader :user

  def week_starting(starts_on)
    answered = answers.fetch(starts_on, [])
    Week.new(starts_on: starts_on, answers: answered.size, correct: answered.count(true),
             clips: clips.fetch(starts_on, 0), minutes_spoken: seconds_spoken[starts_on].fdiv(60).round)
  end

  def range = (@starts.last.beginning_of_day..)

  def answers
    @answers ||= user.review_logs.where(answered_at: range).pluck(:answered_at, :correct)
                     .group_by { |at, _| week_of(at) }.transform_values { |rows| rows.map(&:last) }
  end

  def clips
    @clips ||= user.listens.where(created_at: range).pluck(:created_at).map { |at| week_of(at) }.tally
  end

  def seconds_spoken
    @seconds_spoken ||= ChatMessage.spoken_by(user).where(created_at: range).pluck(:created_at, :spoken_seconds)
                                   .each_with_object(Hash.new(0)) { |(at, seconds), sums| sums[week_of(at)] += seconds }
  end

  def week_of(time) = time.to_date.beginning_of_week
end
