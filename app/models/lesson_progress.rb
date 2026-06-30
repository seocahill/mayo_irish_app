# Small value object describing a user's quiz progress for a lesson.
# Not persisted — built by Lesson#progress_for and reused across views.
class LessonProgress
  attr_reader :known, :total

  def initialize(known:, total:)
    @known = known
    @total = total
  end

  def started? = known.positive?
  def any?     = total.positive?
  def complete? = any? && known >= total

  def pct
    return 0 unless any?
    ((known.to_f / total) * 100).round
  end
end
