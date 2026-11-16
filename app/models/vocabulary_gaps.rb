# Read-only report for course designers: per lesson, which vocabulary items
# still lack a genitive, a plural or a speaker recording.
class VocabularyGaps
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
end
