# Honest markers of how far a learner has got, from what they have actually done:
# words known, time spent listening, sentences made out, whole conversations
# followed, speaking, grammar used, exercises known and noun forms known. Each strand is a short ladder;
# a learner sees the last step they reached and the next one, never points or streaks.
class Milestones
  WORD_STEPS = [ 10, 25, 50, 100, 250, 500, 1000 ].freeze
  LISTENING_MINUTE_STEPS = [ 5, 15, 30, 60, 180, 600 ].freeze
  # Listening clips (a short phrase from a Mayo speaker) the learner said they
  # made out: their own answer, one per clip, not a test score. Counted the way
  # their listening page lists them, so a clip an editor hides drops out of both.
  UNDERSTOOD_CLIP_STEPS = [ 5, 10, 25, 50, 100, 250, 500 ].freeze
  # Whole recordings (a conversation or story from Mayo speakers) the learner
  # said they followed: their own word, one per recording, not a test. Only
  # recordings still offered count (behind a listed clip), like phrases made out;
  # Your listening still lists every recording heard, so it can show one more.
  FOLLOWED_RECORDING_STEPS = [ 1, 3, 5, 10, 25, 50 ].freeze
  # The longest single conversation, in minutes of the learner's own speech.
  CONVERSATION_MINUTE_STEPS = [ 1, 3, 5, 10, 20 ].freeze
  # Lessons whose grammar the learner has shown they can use in conversation with the tutor.
  GRAMMAR_LESSON_STEPS = [ 1, 3, 5, 10, 20, 40 ].freeze
  # Exercises (answered by editors) the learner knows from the daily review:
  # the same bar as a known word, so one lucky answer isn't enough.
  EXERCISE_STEPS = [ 1, 3, 5, 10, 25, 50, 100 ].freeze
  # Plurals and genitives (as the course holds them) the learner knows from
  # their own cards in the daily review, by the same bar as a known word. Kept
  # apart from words known, which counts meanings only.
  NOUN_FORM_STEPS = [ 1, 5, 10, 25, 50, 100, 250 ].freeze

  Strand = Data.define(:key, :value, :reached, :next_step) do
    def started? = reached.present? || value.positive?
    def finished? = next_step.nil?
    def remaining = next_step && (next_step - value)
  end

  def initialize(user, known_words: nil, listening_minutes: nil)
    @user = user
    @known_words = known_words
    @listening_minutes = listening_minutes
  end

  def strands
    [ strand(:words, known_words, WORD_STEPS),
      strand(:listening, @listening_minutes || ListeningTime.minutes_for(@user), LISTENING_MINUTE_STEPS),
      strand(:understood, understood_clips, UNDERSTOOD_CLIP_STEPS),
      strand(:followed, followed_recordings, FOLLOWED_RECORDING_STEPS),
      strand(:conversation, longest_conversation_minutes, CONVERSATION_MINUTE_STEPS),
      strand(:grammar, grammar_lessons, GRAMMAR_LESSON_STEPS),
      (strand(:exercises, known_exercises, EXERCISE_STEPS) if exercises_offered?),
      (strand(:noun_forms, known_noun_forms, NOUN_FORM_STEPS) if noun_forms_offered?) ].compact
  end

  private

  def known_words = @known_words || DailyPath.new(@user).known_words

  def strand(key, value, steps)
    Strand.new(key: key, value: value, reached: steps.select { |step| step <= value }.max,
               next_step: steps.find { |step| step > value })
  end

  def understood_clips
    @user.listens.where(understood: true).joins(:listening_clip).merge(ListeningClip.visible_to(@user)).count
  end

  def followed_recordings
    offered = ListeningClip.visible_to(@user).where.not(abairt_recording_id: nil).select(:abairt_recording_id)
    @user.listening_times.where(followed: true, abairt_recording_id: offered).count
  end

  # Only once the course has an answered exercise this learner can see.
  def exercises_offered?
    Exercise.answered.where(lesson: Lesson.visible_to(@user)).exists?
  end

  def known_exercises
    QuizReview.known.where(user: @user).joins(:quiz_question)
              .merge(QuizQuestion.exercise_cards.still_answerable)
              .where(quiz_questions: { lesson_id: Lesson.visible_to(@user).select(:id) }).count
  end

  # Only once a lesson this learner can see has a word with a plural or genitive.
  def noun_forms_offered?
    VocabularyItem.where(lesson: Lesson.visible_to(@user))
                  .where("COALESCE(plural, '') <> '' OR COALESCE(genitive, '') <> ''").exists?
  end

  def known_noun_forms
    QuizReview.known.where(user: @user).joins(:quiz_question)
              .merge(QuizQuestion.noun_form_cards)
              .where(quiz_questions: { lesson_id: Lesson.visible_to(@user).select(:id) }).count
  end

  def grammar_lessons
    @user.section_progresses.completed.where(section_type: "grammar").count
  end

  def longest_conversation_minutes
    seconds = ChatMessage.spoken_by(@user).group("chat_messages.chat_session_id").sum(:spoken_seconds).values.max.to_i
    seconds.fdiv(60).round
  end
end
