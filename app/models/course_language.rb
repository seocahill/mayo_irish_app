# Tells the course's Irish from its English, using the words of its own phrases
# and vocabulary. Words found in both languages, or in neither, don't count.
#
#   CourseLanguage.current.of("níos/is fearr")  # => :irish
#   CourseLanguage.current.of("up, upwards")    # => :english
class CourseLanguage
  def self.current
    Rails.cache.fetch([ "course-language", Phrase.all, VocabularyItem.all ]) do
      new(irish: Phrase.pluck(:irish) + VocabularyItem.pluck(:irish),
          english: Phrase.pluck(:english) + VocabularyItem.pluck(:english))
    end
  end

  def initialize(irish:, english:)
    @irish = vocabulary(irish)
    @english = vocabulary(english)
  end

  # :irish, :english, or nil when it can't tell. A fada tips a tie towards Irish.
  def of(text)
    words = IrishText.words(text)
    irish = words.count { |word| @irish.include?(word) && !@english.include?(word) }
    english = words.count { |word| @english.include?(word) && !@irish.include?(word) }

    if irish != english
      (irish > english) ? :irish : :english
    elsif text.match?(/[áéíóú]/i)
      :irish
    end
  end

  private

  def vocabulary(texts) = texts.flat_map { |text| IrishText.words(text) }.to_set
end
