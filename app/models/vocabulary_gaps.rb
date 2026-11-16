# Read-only report for course designers: per lesson, which vocabulary items
# still lack a genitive, a plural or a speaker recording.
class VocabularyGaps
  THEMES_FILE = Rails.root.join("config/course_themes.yml")
  THIN = 3

  Theme = Struct.new(:name, :count, :examples, keyword_init: true)

  Row = Struct.new(:lesson, :items, keyword_init: true) do
    def missing(item)
      VocabularyGaps.missing_for(item)
    end
  end

  def self.missing_for(item)
    missing = []
    missing << :genitive if item.genitive.blank?
    missing << :plural if item.plural.blank?
    missing << :recording unless item.audio_url.present? || item.audio.attached?
    missing
  end

  def rows
    @rows ||= build_rows
  end

  def build_rows
    Lesson.includes(vocabulary_items: { audio_attachment: :blob }).order(:position, :number).filter_map do |lesson|
      items = lesson.vocabulary_items.select { |i| self.class.missing_for(i).any? }
      Row.new(lesson: lesson, items: items) if items.any?
    end
  end

  def totals
    all = rows.flat_map(&:items)
    %i[genitive plural recording].index_with { |k| all.count { |i| self.class.missing_for(i).include?(k) } }
  end

  Repeat = Struct.new(:irish, :items, keyword_init: true)

  # Irish words that appear in more than one lesson (case-insensitive, same
  # spelling). A prompt for designers: a repeat may be deliberate.
  def repeats
    @repeats ||= build_repeats
  end

  # Everyday themes with few vocabulary items (matched by whole English word
  # against each item's gloss), thinnest first. Read-only prompt for designers.
  def thin_themes
    @thin_themes ||= build_themes.select { |t| t.count < THIN }.sort_by { |t| [ t.count, t.name ] }
  end

  private

  def self.stem(word)
    word.delete_suffix("'s").sub(/(?<=[a-z])(es|s)\z/, "")
  end

  def self.themes_config
    @themes_config ||= Array(YAML.safe_load_file(THEMES_FILE)).filter_map do |t|
      words = Array(t["keywords"]).map { |k| stem(k.to_s.downcase) }.reject(&:blank?)
      { name: t["name"].to_s, words: words.to_set } if t.is_a?(Hash) && t["name"].present?
    end
  end

  def build_themes
    glosses = VocabularyItem.order(:id).pluck(:english, :irish).map do |en, ga|
      [ en.to_s.downcase.scan(/[a-z]+/).map { |w| self.class.stem(w) }.to_set, ga ]
    end
    self.class.themes_config.map do |theme|
      hits = glosses.select { |tokens, _| tokens.intersect?(theme[:words]) }
      Theme.new(name: theme[:name], count: hits.size, examples: hits.first(THIN).map(&:last).uniq)
    end
  end

  def build_repeats
    groups = VocabularyItem.includes(:lesson).group_by { |i| i.irish.to_s.strip.unicode_normalize.downcase }
    groups.reject { |word, _| word.empty? }.filter_map do |_, items|
      items = items.uniq(&:lesson_id).sort_by { |i| [ i.lesson.position, i.lesson.number ] }
      Repeat.new(irish: items.first.irish, items: items) if items.size > 1
    end.sort_by { |r| r.irish.downcase }
  end
end
