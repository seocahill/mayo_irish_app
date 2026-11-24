# Read-only report for course designers: the exercises (answered by editors)
# that learners most often rate Again in the daily review, hardest first. An
# exercise card is self-rated, so Again is the learner's own word that they
# couldn't produce it. Same rules as HardWords: approved learners only (not
# admins), the last DAYS days, at least MIN_ANSWERS answers.
class HardExercises
  DAYS = HardWords::DAYS
  MIN_ANSWERS = HardWords::MIN_ANSWERS
  LIMIT = HardWords::LIMIT

  Row = Data.define(:exercise, :answers, :misses, :learners) do
    def miss_percent = (misses * 100.0 / answers).round
  end

  def initialize(now: Time.current, limit: LIMIT)
    @since = now - DAYS.days
    @limit = limit
  end

  def rows
    @rows ||= build_rows
  end

  private

  def build_rows
    stats = logs.group("quiz_questions.source_id")
                .having("COUNT(*) >= ? AND SUM(CASE WHEN review_logs.correct THEN 0 ELSE 1 END) > 0", MIN_ANSWERS)
                .pluck(Arel.sql("quiz_questions.source_id"), Arel.sql("COUNT(*)"),
                       Arel.sql("SUM(CASE WHEN review_logs.correct THEN 0 ELSE 1 END)"),
                       Arel.sql("COUNT(DISTINCT CASE WHEN review_logs.correct THEN NULL ELSE review_logs.user_id END)"))
    exercises = Exercise.where(id: stats.map(&:first)).includes(:lesson).index_by(&:id)
    stats.filter_map { |id, answers, misses, learners| exercises[id] && Row.new(exercise: exercises[id], answers:, misses:, learners:) }
         .sort_by { |row| [ -row.misses.fdiv(row.answers), -row.misses, row.exercise.lesson.position.to_i, row.exercise.number, row.exercise.id ] }
         .first(@limit)
  end

  # Answers whose exercise has since been deleted lose their card and are left
  # out by the join.
  def logs
    ReviewLog.joins(:quiz_question).merge(QuizQuestion.exercise_cards)
             .where(user_id: User.where(approved: true, admin: false).select(:id), answered_at: @since..)
  end
end
