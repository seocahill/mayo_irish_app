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
    if item.part_of_speech == "noun"
      missing << :genitive if item.genitive.blank?
      missing << :plural if item.plural.blank?
    end
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

  UNCLASSIFIED_PER_PAGE = 50

  # Words an editor hasn't yet marked as a noun, verb and so on. Gaps for
  # genitive and plural are only counted once a word is marked as a noun.
  def unclassified_count
    @unclassified_count ||= VocabularyItem.unclassified.count
  end

  def unclassified(page: 1)
    VocabularyItem.unclassified.includes(:lesson).order(:lesson_id, :position, :id)
                  .offset((page.to_i.clamp(1, 10_000) - 1) * UNCLASSIFIED_PER_PAGE).limit(UNCLASSIFIED_PER_PAGE)
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

  Silent = Struct.new(:lesson, :count, keyword_init: true)

  # Lessons with vocabulary where not one word has a speaker recording, so
  # designers can see where native audio is wholly missing. Read-only.
  def silent_lessons
    @silent_lessons ||= Lesson.includes(vocabulary_items: { audio_attachment: :blob }).order(:position, :number).filter_map do |lesson|
      items = lesson.vocabulary_items.to_a
      next if items.empty? || items.any? { |i| !self.class.missing_for(i).include?(:recording) }

      Silent.new(lesson: lesson, count: items.size)
    end
  end

  Unpractised = Struct.new(:lesson, :count, keyword_init: true)

  # Lessons with vocabulary but no exercises and no phrases, so designers can
  # see where there is nothing to practise the words on. Read-only.
  def unpractised_lessons
    @unpractised_lessons ||= Lesson.includes(:vocabulary_items, :exercises, :phrases).order(:position, :number).filter_map do |lesson|
      next if lesson.vocabulary_items.empty? || lesson.exercises.any? || lesson.phrases.any?

      Unpractised.new(lesson: lesson, count: lesson.vocabulary_items.size)
    end
  end

  Ungrammared = Struct.new(:lesson, :count, keyword_init: true)

  # Lessons with vocabulary but no grammar rules, so designers can see where no
  # grammar point is taught yet. Read-only.
  def ungrammared_lessons
    @ungrammared_lessons ||= Lesson.includes(:vocabulary_items, :grammar_rules).order(:position, :number).filter_map do |lesson|
      next if lesson.vocabulary_items.empty? || lesson.grammar_rules.any?

      Ungrammared.new(lesson: lesson, count: lesson.vocabulary_items.size)
    end
  end

  Unlistened = Struct.new(:lesson, :count, keyword_init: true)

  # Lessons with vocabulary where no word has a listed listening clip, so
  # designers can see where learners have no native phrase to work out. Read-only.
  def unlistened_lessons
    @unlistened_lessons ||= begin
      with_clips = VocabularyItem.where(id: ListeningClip.listed.select(:vocabulary_item_id)).distinct.pluck(:lesson_id)
      Lesson.includes(:vocabulary_items).where.not(id: with_clips).order(:position, :number).filter_map do |lesson|
        Unlistened.new(lesson: lesson, count: lesson.vocabulary_items.size) if lesson.vocabulary_items.any?
      end
    end
  end

  # Lessons with no vocabulary at all, so designers can see which lessons are
  # still empty shells. Read-only.
  def empty_lessons
    @empty_lessons ||= Lesson.where.not(id: VocabularyItem.select(:lesson_id)).order(:position, :number).to_a
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
