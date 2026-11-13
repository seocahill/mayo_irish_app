# Course-wide figures for the admin Usage page, from what learners already
# record. Nothing here is sent anywhere. Weeks start on Monday and run oldest
# first; each figure is one query over the whole period.
class UsageReport
  WEEKS = 12

  Week = Data.define(:starts_on, :active, :returning, :retention, :answers, :accuracy, :minutes_listened, :minutes_spoken, :lessons_started, :questions)
  Stage = Data.define(:lesson, :opened, :quizzed)

  def initialize(now: Time.current)
    @first = (now.beginning_of_week - (WEEKS - 1).weeks)
  end

  def weeks
    @weeks ||= week_starts.each_with_index.map { |start, i| week(start, i) }
  end

  # For each curriculum lesson: how many learners opened it, and how many went on to answer its quiz.
  def stages
    opened = LessonVisit.group(:lesson_id).distinct.count(:user_id)
    quizzed = QuizReview.joins(:quiz_question).group("quiz_questions.lesson_id").distinct.count(:user_id)
    Lesson.curriculum.published.ordered.map do |lesson|
      Stage.new(lesson: lesson, opened: opened.fetch(lesson.id, 0), quizzed: quizzed.fetch(lesson.id, 0))
    end
  end

  private

  def week_starts = Array.new(WEEKS) { |i| @first + i.weeks }

  def week(start, i)
    key = bucket(start)
    active = learners_by_week.fetch(key, Set.new)
    before = i.zero? ? nil : learners_by_week.fetch(bucket(week_starts[i - 1]), Set.new)
    returning = before ? (active & before).size : nil
    right, total = answer_counts.fetch(key, [ 0, 0 ])
    Week.new(starts_on: start.to_date, active: active.size, returning: returning,
             retention: (before.present? ? (returning * 100.0 / before.size).round : nil),
             answers: total, accuracy: (total.positive? ? (right * 100.0 / total).round : nil),
             minutes_listened: minutes(listening_seconds[key]), minutes_spoken: minutes(spoken_seconds[key]),
             lessons_started: lessons_started.fetch(key, 0), questions: questions.fetch(key, 0))
  end

  def bucket(time) = time.to_date.beginning_of_week

  def minutes(seconds) = seconds.to_i.fdiv(60).round

  def answer_logs = @answer_logs ||= ReviewLog.where(answered_at: @first..).pluck(:user_id, :answered_at, :correct)

  def answer_counts
    @answer_counts ||= answer_logs.group_by { |_, at, _| bucket(at) }
                                  .transform_values { |logs| [ logs.count { |l| l[2] }, logs.size ] }
  end

  def listening_seconds
    @listening_seconds ||= ListeningTime.where(updated_at: @first..).pluck(:updated_at, :seconds)
                                        .group_by { |at, _| bucket(at) }.transform_values { |r| r.sum { |_, s| s } }
  end

  def spoken_rows
    @spoken_rows ||= ChatMessage.where(role: "user").where.not(spoken_seconds: nil).joins(:chat_session)
                                .where(created_at: @first..).pluck("chat_sessions.user_id", :created_at, :spoken_seconds)
  end

  def spoken_seconds
    @spoken_seconds ||= spoken_rows.group_by { |_, at, _| bucket(at) }.transform_values { |r| r.sum { |_, _, s| s } }
  end

  def lessons_started
    @lessons_started ||= LessonVisit.where(created_at: @first..).pluck(:created_at)
                                    .group_by { |at| bucket(at) }.transform_values(&:size)
  end

  def questions
    @questions ||= NativeQuestion.where(created_at: @first..).pluck(:created_at)
                                 .group_by { |at| bucket(at) }.transform_values(&:size)
  end

  # Learners who did anything that counts as using the course, by week.
  def learners_by_week
    @learners_by_week ||= begin
      seen = Hash.new { |h, k| h[k] = Set.new }
      answer_logs.each { |user, at, _| seen[bucket(at)] << user }
      Listen.where(created_at: @first..).pluck(:user_id, :created_at).each { |user, at| seen[bucket(at)] << user }
      ListeningTime.where(updated_at: @first..).pluck(:user_id, :updated_at).each { |user, at| seen[bucket(at)] << user }
      spoken_rows.each { |user, at, _| seen[bucket(at)] << user }
      seen
    end
  end
end
