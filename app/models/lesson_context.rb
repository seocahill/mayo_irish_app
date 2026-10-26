# The lesson material an AI chat is given to work from, as plain text: the
# intro video's transcript, the grammar rules and the vocabulary. Shared by the
# tutor chat and the comhrá so both see the lesson the same way.
class LessonContext
  def initialize(lesson)
    @lesson = lesson
  end

  BRIEF_INTRO_CHARACTERS = 1500

  def to_s
    [ intro, grammar, vocabulary ].compact.join("\n\n")
  end

  # A shorter version for the comhrá: all the vocabulary, but only the grammar
  # rules' titles and the start of the intro, so even the longest lesson stays
  # around 3,000 characters.
  def brief
    [ intro&.truncate(BRIEF_INTRO_CHARACTERS), grammar_titles, vocabulary ].compact.join("\n\n")
  end

  def intro
    return if @lesson.intro_video_transcript.blank?

    "LESSON INTRODUCTION (transcript of the teacher's intro video):\n#{@lesson.intro_video_transcript.strip}"
  end

  def grammar
    return @grammar if defined?(@grammar)

    rules = @lesson.grammar_rules.includes(:grammar_sections)
    @grammar = (rules_text(rules) if rules.any?)
  end

  def vocabulary
    return @vocabulary if defined?(@vocabulary)

    items = @lesson.vocabulary_items.to_a
    @vocabulary = (vocabulary_text(items) if items.any?)
  end

  def grammar_titles
    titles = @lesson.grammar_rules.map(&:title)
    return if titles.empty?

    ([ "GRAMMAR RULES (titles only):" ] + titles.each_with_index.map { |title, i| "#{i + 1}. #{title}" }).join("\n")
  end

  private

  def rules_text(rules)
    lines = [ "GRAMMAR RULES:" ]
    rules.each do |rule|
      lines << "\n#{rule.number}. #{rule.title}"
      lines << rule.body.to_plain_text.strip if rule.body.present?
      rule.grammar_sections.each do |section|
        lines << "  #{section.label}:" if section.label.present?
        lines << "  #{section.body.to_plain_text.strip}" if section.body.present?
      end
    end
    lines.join("\n")
  end

  def vocabulary_text(items)
    lines = [ "VOCABULARY:" ]
    items.each do |v|
      gender = (v.gender == "m") ? "masc." : "fem."
      parts = [ "#{v.irish} (#{gender})" ]
      parts << "pl. #{v.plural}" if v.plural.present?
      parts << "— #{v.english}" if v.english.present?
      lines << parts.join(" ")
    end
    lines.join("\n")
  end
end
