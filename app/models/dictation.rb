# What a learner typed after hearing a listening clip, lined up word by word
# against the clip's own transcript (the speaker's words; nothing is generated
# or corrected). Case, punctuation and missing fadas are ignored: a word typed
# without its fada counts as heard, and is shown so the learner sees the fada.
class Dictation
  MAX_LENGTH = 500

  # status is :heard, :missed or :different; typed is what the learner wrote
  # in its place (for :different, or :heard without the fada).
  Word = Data.define(:text, :status, :typed) do
    def heard? = status == :heard
    # The speaker's word has a fada the learner left out (an extra fada isn't flagged).
    def fada_missing? = heard? && Dictation.bare(text) != Dictation.key(text) && Dictation.bare(typed) != Dictation.bare(text)
  end

  def self.tokens(text) = text.to_s.split(/[\s–—]+/).filter_map { |w| w.gsub(/\A[^\p{L}\p{N}]+|[^\p{L}\p{N}]+\z/, "").presence }

  # Lower case, no punctuation: the word as written, fadas kept.
  def self.bare(word) = word.to_s.downcase.gsub(/[^\p{L}\p{N}]/, "")

  # The same with fadas folded away, for matching.
  def self.key(word) = bare(word).unicode_normalize(:nfd).gsub(/\p{Mn}/, "")

  def initialize(transcript, typed)
    @expected = self.class.tokens(transcript)
    @typed = self.class.tokens(typed.to_s.first(MAX_LENGTH))
  end

  def words = @words ||= align

  def heard_count = words.count(&:heard?)

  def all_heard? = words.any? && words.all?(&:heard?)

  def attempted? = @typed.any?

  private

  # Longest common subsequence on the folded words; between two matches, the
  # learner's leftover words are paired in order with the speaker's leftover
  # words (different), and speaker words with no partner are missed.
  def align
    exp = @expected.map { |w| self.class.key(w) }
    typ = @typed.map { |w| self.class.key(w) }
    lengths = Array.new(exp.size + 1) { Array.new(typ.size + 1, 0) }
    (exp.size - 1).downto(0) do |i|
      (typ.size - 1).downto(0) do |j|
        lengths[i][j] = exp[i] == typ[j] ? lengths[i + 1][j + 1] + 1 : [ lengths[i + 1][j], lengths[i][j + 1] ].max
      end
    end

    result = []
    gap_expected = []
    gap_typed = []
    i = j = 0
    flush = lambda do
      gap_expected.each_with_index do |e, n|
        t = gap_typed[n]
        result << Word.new(text: @expected[e], status: t ? :different : :missed, typed: t && @typed[t])
      end
      gap_expected.clear
      gap_typed.clear
    end

    while i < exp.size && j < typ.size
      if exp[i] == typ[j]
        flush.call
        result << Word.new(text: @expected[i], status: :heard, typed: @typed[j])
        i += 1
        j += 1
      elsif lengths[i + 1][j] >= lengths[i][j + 1]
        gap_expected << i
        i += 1
      else
        gap_typed << j
        j += 1
      end
    end
    gap_expected.concat((i...exp.size).to_a)
    gap_typed.concat((j...typ.size).to_a)
    flush.call
    result
  end
end
