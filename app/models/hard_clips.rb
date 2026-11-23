# Read-only report for course designers: the listening clips (a Mayo speaker's
# phrase) that learners most often said they couldn't make out, hardest first.
# Each learner has one answer per clip, their latest. Counts approved learners
# only (not admins), and listed clips only: a hidden clip is already dealt with.
class HardClips
  LIMIT = 30

  Row = Data.define(:clip, :answers, :not_yet) do
    def not_yet_percent = (not_yet * 100.0 / answers).round
  end

  def initialize(limit: LIMIT)
    @limit = limit
  end

  def rows
    @rows ||= build_rows
  end

  private

  def build_rows
    stats = listens.group(:listening_clip_id)
                   .having("SUM(CASE WHEN listens.understood THEN 0 ELSE 1 END) > 0")
                   .pluck(:listening_clip_id, Arel.sql("COUNT(*)"),
                          Arel.sql("SUM(CASE WHEN listens.understood THEN 0 ELSE 1 END)"))
    clips = ListeningClip.listed.where(id: stats.map(&:first)).includes(vocabulary_item: :lesson).index_by(&:id)
    stats.filter_map { |id, answers, not_yet| clips[id] && Row.new(clip: clips[id], answers:, not_yet:) }
         .sort_by { |row| [ -row.not_yet.fdiv(row.answers), -row.not_yet, row.clip.word_count, row.clip.id ] }
         .first(@limit)
  end

  def listens
    Listen.where(user_id: User.where(approved: true, admin: false).select(:id))
  end
end
