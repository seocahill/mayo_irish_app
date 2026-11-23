# The course's own words that turn up in an exercise's prompt, shown to an
# editor writing the exercise's Mayo answer: vocabulary from this lesson and
# the ones before it whose Irish (for an Irish prompt) or English (for an
# English prompt) appears in it, this lesson's first. Also any Mayo forms pair
# whose other form is in an Irish prompt. Read-only, and it never writes or
# changes any Irish.
class ExerciseWords
  LIMIT = 12
  MIN_LENGTH = 3

  # When the course's own vocabulary can't tell the prompt's language, these
  # mark it as English. None is an Irish word once accents are set aside ("he",
  # "a" and "am" are: "Ní hé", "a dhuine", "an t-am").
  ENGLISH_MARKERS = %w[the you your was were she they we it are of to and that this what where who
                       with have has not my his her our their there yesterday how why when which
                       does would will can].to_set.freeze
  # English glosses too common to be worth showing on their own.
  STOP_GLOSSES = %w[the and are was were you she they not have has with that this there what who where
                    for from but one all any its out off will can did had him her].to_set.freeze
  # Eclipsis, longest first; lenition is an h after the first consonant.
  ECLIPSES = %w[bhf mb gc nd ng bp dt].freeze
  LENITABLE = %w[b c d f g m p s t].freeze
  # Prompt words whose look-alike base form is a different word ("bhfuil" is
  # "tá", not "fuil", blood).
  NOT_MUTATED = %w[bhfuil].to_set.freeze

  Match = Data.define(:item, :lesson)

  attr_reader :exercise

  def initialize(exercise)
    @exercise = exercise
  end

  def english?
    return @english if defined?(@english)

    language = CourseLanguage.current.of(exercise.prompt)
    @english = language ? language == :english : IrishText.words(exercise.prompt).any? { |word| ENGLISH_MARKERS.include?(word) }
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
      prompt_words = IrishText.words(exercise.prompt)
      bare_words = (prompt_words + prompt_words.map { |word| demutate(word) }).to_set
      lessons = lessons_so_far.index_by(&:id)
      rank = lessons.values.sort_by { |l| [ l.id == exercise.lesson_id ? 0 : 1, l.position, l.id ] }
                    .each_with_index.to_h { |lesson, index| [ lesson.id, index ] }

      VocabularyItem.where(lesson_id: lessons.keys).select(:id, :lesson_id, :irish, :english, :position)
                    .select { |item| english? ? english_match?(item, prompt_words) : irish_match?(item, prompt_words, bare_words) }
                    .sort_by { |item| [ rank[item.lesson_id], item.position, item.id ] }
                    .uniq { |item| [ IrishText.words(item.irish), item.english.downcase ] }
                    .map { |item| Match.new(item: item, lesson: lessons[item.lesson_id]) }
    end
  end

  # This lesson and the lessons before it in the course, so the words shown
  # are ones a learner has already met.
  def lessons_so_far
    lesson = exercise.lesson
    Lesson.where(id: VocabularyItem.select(:lesson_id))
          .where("position < :position OR id = :id", position: lesson.position, id: lesson.id).to_a
  end

  def irish_match?(item, prompt_words, bare_words)
    pieces(item.irish).any? do |needle|
      # Two-letter words ("an", "ar", "ná") are everywhere and would crowd out the rest.
      next false if needle.join.length < MIN_LENGTH
      next true if prompt_words.each_cons(needle.size).include?(needle)

      # A single word also matches a mutated form in the prompt: "bhean" for "bean".
      needle.size == 1 && bare_words.include?(needle.first)
    end
  end

  def english_match?(item, prompt_words)
    pieces(item.english).any? do |words|
      next false if words.join.length < MIN_LENGTH || (words.size == 1 && STOP_GLOSSES.include?(words.first))

      prompt_words.each_cons(words.size).include?(words)
    end
  end

  # Each part of a headword or gloss as its words: "palm (of hand)" ->
  # [["palm"]]; "sé, seisean" -> [["se"], ["seisean"]]. A leading "a", "an",
  # "the" or "to" is dropped from a part of several words.
  def pieces(text)
    text.to_s.gsub(/\([^)]*\)/, " ").split(/[,;\/]/).filter_map do |part|
      words = IrishText.words(part)
      words.shift if words.size > 1 && %w[a an the to].include?(words.first)
      words.presence
    end
  end

  # A prompt word with an initial mutation taken off, for matching only.
  def demutate(word)
    return word if NOT_MUTATED.include?(word)

    word = word.sub(/\A(?:[dbm]'|')/, "")
    eclipsis = ECLIPSES.find { |prefix| word.start_with?(prefix) && word.length > prefix.length + 1 }
    return word[(eclipsis.length - 1)..] if eclipsis
    return word[1..] if word.length > 3 && word.start_with?("ts")
    return word[0] + word[2..] if word.length > 3 && LENITABLE.include?(word[0]) && word[1] == "h"
    return word[1..] if word.length > 3 && word[0] == "h" && word[1].match?(/[aeiou]/)

    word
  end
end
