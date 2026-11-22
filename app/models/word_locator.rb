# Where a word is taught, heard and practised in the course: the vocabulary
# items that match it, with their recordings, listening clips and review
# questions, and the lessons that use it in a phrase or exercise. Read-only;
# shared by the "Where is it taught" page and the where_is_taught MCP tool.
class WordLocator
  LIMIT = 10
  MIN_LENGTH = 2

  Match = Data.define(:item, :has_recording, :listening_clips, :quiz_questions)

  attr_reader :term

  def initialize(term)
    @term = term.to_s.strip
  end

  def valid?
    term.length >= MIN_LENGTH
  end

  def matches
    return [] unless valid?

    @matches ||= begin
      items = VocabularyItem.includes(:lesson, :audio_attachment)
                            .where("irish LIKE :q ESCAPE '\\' OR english LIKE :q ESCAPE '\\'", q: like)
                            .order(:lesson_id, :position).limit(LIMIT + 1).to_a
      @more_matches = items.size > LIMIT
      items = items.first(LIMIT)
      ids = items.map(&:id)
      clips = ListeningClip.where(vocabulary_item_id: ids).group(:vocabulary_item_id).count
      quizzes = QuizQuestion.where(source_type: "VocabularyItem", source_id: ids).group(:source_id).count
      items.map do |item|
        Match.new(item: item, has_recording: item.audio.attached? || item.audio_url.present?,
                  listening_clips: clips[item.id].to_i, quiz_questions: quizzes[item.id].to_i)
      end
    end
  end

  def phrase_lessons
    all_phrase_lessons.first(LIMIT)
  end

  def exercise_lessons
    all_exercise_lessons.first(LIMIT)
  end

  # Whether more than LIMIT words or lessons matched, so a page can say it
  # shows only the first ones.
  def more_matches?
    matches
    @more_matches.present?
  end

  def more_phrase_lessons? = all_phrase_lessons.size > LIMIT
  def more_exercise_lessons? = all_exercise_lessons.size > LIMIT

  private

  def all_phrase_lessons
    return [] unless valid?

    @all_phrase_lessons ||= lessons_for(Phrase.where("irish LIKE :q ESCAPE '\\' OR english LIKE :q ESCAPE '\\'", q: like).distinct.pluck(:lesson_id))
  end

  def all_exercise_lessons
    return [] unless valid?

    @all_exercise_lessons ||= lessons_for(Exercise.where("prompt LIKE :q ESCAPE '\\' OR answer LIKE :q ESCAPE '\\'", q: like).distinct.pluck(:lesson_id))
  end

  def like
    "%#{VocabularyItem.sanitize_sql_like(term)}%"
  end

  def lessons_for(ids)
    Lesson.where(id: ids.uniq).order(:number).limit(LIMIT + 1).to_a
  end
end
