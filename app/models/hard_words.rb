# Read-only report for course designers: the vocabulary words learners answer
# wrongly most often in review, hardest first. Counts approved learners only
# (not admins), over the last DAYS days, both directions of a word together.
class HardWords
  DAYS = 90
  MIN_ANSWERS = 3
  LIMIT = 30

  Row = Data.define(:item, :answers, :misses, :learners) do
    def miss_percent = (misses * 100.0 / answers).round
  end

  def initialize(now: Time.current)
    @since = now - DAYS.days
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
    items = VocabularyItem.where(id: stats.map(&:first)).includes(:lesson).index_by(&:id)
    stats.filter_map { |id, answers, misses, learners| items[id] && Row.new(item: items[id], answers:, misses:, learners:) }
         .sort_by { |row| [ -row.misses.fdiv(row.answers), -row.misses, row.item.irish.downcase ] }
         .first(LIMIT)
  end

  def logs
    ReviewLog.joins(:quiz_question)
             .where(user_id: User.where(approved: true, admin: false).select(:id), answered_at: @since..,
                    quiz_questions: { source_type: "VocabularyItem" })
  end
end
