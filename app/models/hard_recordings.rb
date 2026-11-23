# Read-only report for course designers: the whole recordings (a conversation
# or story from Abairt, behind the course's listening clips) that learners most
# often said they couldn't follow yet, hardest first. Each learner has one
# answer per recording, their latest. Counts approved learners only (not
# admins), and offered recordings only (behind a listed clip).
class HardRecordings
  LIMIT = 30

  Row = Data.define(:recording_id, :title, :lesson, :questions, :answers, :not_yet) do
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
    stats = answers.group(:abairt_recording_id)
                   .having("SUM(CASE WHEN listening_times.followed THEN 0 ELSE 1 END) > 0")
                   .pluck(:abairt_recording_id, Arel.sql("COUNT(*)"),
                          Arel.sql("SUM(CASE WHEN listening_times.followed THEN 0 ELSE 1 END)"))
    ids = stats.map(&:first)
    leads = first_lessons(ids)
    questions = RecordingQuestion.where(abairt_recording_id: ids).group(:abairt_recording_id).count
    stats.filter_map do |id, answers, not_yet|
      lesson, title = leads[id]
      lesson && Row.new(recording_id: id, title:, lesson:, questions: questions.fetch(id, 0), answers:, not_yet:)
    end.sort_by { |row| [ -row.not_yet.fdiv(row.answers), -row.not_yet, row.lesson.position.to_i, row.recording_id ] }
       .first(@limit)
  end

  def answers
    ListeningTime.where.not(followed: nil).where(user_id: User.where(approved: true, admin: false).select(:id))
  end

  # The first lesson in the course that leads to each recording (through a
  # listed clip), and the recording's title as the clips have it.
  def first_lessons(ids)
    rows = ListeningClip.listed.where(abairt_recording_id: ids).joins(vocabulary_item: :lesson)
                        .order("lessons.position", "lessons.number", :id)
                        .pluck(:abairt_recording_id, "lessons.id", :abairt_recording_title)
    lessons = Lesson.where(id: rows.map(&:second)).index_by(&:id)
    rows.group_by(&:first).transform_values do |same|
      [ lessons[same.first.second], same.map(&:last).find(&:present?) ]
    end
  end
end
