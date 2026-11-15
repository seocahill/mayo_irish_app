# Honest markers of how far a learner has got, from what they have actually done:
# words known, time spent listening, and speaking. Each strand is a short ladder;
# a learner sees the last step they reached and the next one, never points or streaks.
class Milestones
  WORD_STEPS = [ 10, 25, 50, 100, 250, 500, 1000 ].freeze
  LISTENING_MINUTE_STEPS = [ 5, 15, 30, 60, 180, 600 ].freeze
  # The longest single conversation, in minutes of the learner's own speech.
  CONVERSATION_MINUTE_STEPS = [ 1, 3, 5, 10, 20 ].freeze

  Strand = Data.define(:key, :value, :reached, :next_step) do
    def started? = reached.present? || value.positive?
    def finished? = next_step.nil?
    def remaining = next_step && (next_step - value)
  end

  def initialize(user, known_words: nil)
    @user = user
    @known_words = known_words
  end

  def strands
    [ strand(:words, known_words, WORD_STEPS),
      strand(:listening, ListeningTime.minutes_for(@user), LISTENING_MINUTE_STEPS),
      strand(:conversation, longest_conversation_minutes, CONVERSATION_MINUTE_STEPS) ]
  end

  private

  def known_words = @known_words || DailyPath.new(@user).known_words

  def strand(key, value, steps)
    Strand.new(key: key, value: value, reached: steps.select { |step| step <= value }.max,
               next_step: steps.find { |step| step > value })
  end

  def longest_conversation_minutes
    seconds = ChatMessage.spoken_by(@user).group("chat_messages.chat_session_id").sum(:spoken_seconds).values.max.to_i
    seconds / 60
  end
end
