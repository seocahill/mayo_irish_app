# The course's own words that turn up in an exercise's prompt, shown to an
# editor writing the exercise's Mayo answer: vocabulary whose Irish (for an
# Irish prompt) or English (for an English prompt) appears in it, this lesson's
# first, then the course in order. Also any Mayo forms pair whose other form is
# in an Irish prompt. Read-only, and it never writes or changes any Irish.
class ExerciseWords
  LIMIT = 12
  MIN_LENGTH = 3

  # Words that mark a prompt as English. None of them is an Irish word once
  # accents are set aside ("he" and "a" are, as in "Ní hé" and "a dhuine").
  ENGLISH_MARKERS = %w[the you your was were she they we it are of to and that this what where who
                       with have has not my his her our their there yesterday am how why when which does would will can].to_set.freeze
  # English glosses too common to be worth showing on their own.
  STOP_GLOSSES = %w[the and are was were you she they not have has with that this there what who where
                    for from but one all any its out off will can did had him her].to_set.freeze
  # Eclipsis, longest first; lenition is an h after the first consonant.
  ECLIPSES = %w[bhf mb gc nd ng bp dt].freeze
  LENITABLE = %w[b c d f g m p s t].freeze

  Match = Data.define(:item, :lesson)

  attr_reader :exercise

  def initialize(exercise)
    @exercise = exercise
  end

  def english?
    IrishText.words(exercise.prompt).any? { |word| ENGLISH_MARKERS.include?(word) }
  end

  def matches
    all_matches.first(LIMIT)
  end

  def more? = all_matches.size > LIMIT

  # Mayo forms pairs whose other (Connemara or standard) form is in the prompt.
  def substitutions
    return [] if english?

    @substitutions ||= DialectSubstitution.ordered.select { |s| IrishText.includes?(exercise.prompt, s.other_form) }
  end

  private

  def all_matches
    @all_matches ||= begin
      english = english?
      prompt_words = IrishText.words(exercise.prompt)
      bare_words = prompt_words.map { |word| demutate(word) }.to_set
      lessons = Lesson.where(id: VocabularyItem.select(:lesson_id)).index_by(&:id)
      rank = lessons.values.sort_by { |l| [ l.id == exercise.lesson_id ? 0 : 1, l.position, l.id ] }
                    .each_with_index.to_h { |lesson, index| [ lesson.id, index ] }

      found = VocabularyItem.where(lesson_id: lessons.keys).order(:position, :id).select do |item|
        english ? english_match?(item, prompt_words) : irish_match?(item, prompt_words, bare_words)
      end
      found.uniq { |item| [ IrishText.words(item.irish), item.english.downcase ] }
           .sort_by { |item| [ rank[item.lesson_id], item.position, item.id ] }
           .map { |item| Match.new(item: item, lesson: lessons[item.lesson_id]) }
    end
  end

  def irish_match?(item, prompt_words, bare_words)
    needle = IrishText.words(item.irish)
    # Two-letter words ("an", "ar", "ná") are everywhere and would crowd out the rest.
    return false if needle.empty? || needle.join.length < MIN_LENGTH
    return true if prompt_words.each_cons(needle.size).include?(needle)

    # A single word also matches with an initial mutation: "bhean" for "bean".
    needle.size == 1 && bare_words.include?(demutate(needle.first))
  end

  def english_match?(item, prompt_words)
    glosses(item.english).any? { |words| prompt_words.each_cons(words.size).include?(words) }
  end

  # Each gloss as its words: "palm (of hand)" -> [["palm"]]; "on the point of,
  # about to" -> two glosses. A leading "a", "an", "the" or "to" is dropped, and
  # very common words are skipped.
  def glosses(english)
    english.to_s.gsub(/\([^)]*\)/, " ").split(/[,;\/]/).filter_map do |gloss|
      words = IrishText.words(gloss)
      words.shift if words.size > 1 && %w[a an the to].include?(words.first)
      next if words.join.length < MIN_LENGTH || (words.size == 1 && STOP_GLOSSES.include?(words.first))
      words
    end
  end

  # The word with an initial mutation taken off, for matching only.
  def demutate(word)
    eclipsis = ECLIPSES.find { |prefix| word.start_with?(prefix) && word.length > prefix.length + 1 }
    return word[(eclipsis.length - 1)..] if eclipsis
    return word[0] + word[2..] if word.length > 3 && LENITABLE.include?(word[0]) && word[1] == "h"
    return word[1..] if word.length > 3 && word[0] == "h" && word[1].match?(/[aeiou]/)

    word
  end
end
