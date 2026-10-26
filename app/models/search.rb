# Global full-text search across every Searchable model, backed by the
# `search_documents` FTS5 table.
#
#   Search.new("failte").results  # => [Search::Result, ...] ranked by relevance
#
# Diacritics are folded by the index (see the migration), so searches work the
# same whether the user types Irish fadas or plain English letters.
class Search
  MAX_RESULTS = 50

  # Sentinel characters wrap highlighted terms in the snippet. They can't occur
  # in real content, so the view can HTML-escape the snippet and *then* swap
  # them for <mark> tags without any XSS risk.
  HIGHLIGHT_OPEN = "\u0002"
  HIGHLIGHT_CLOSE = "\u0003"

  # Only these record types are searchable (labels live in the locale file). The
  # book's reading texts and exercises are not shown to learners.
  TYPES = %w[Lesson VocabularyItem Phrase GrammarRule GrammarSection LessonBlock].freeze

  Result = Struct.new(:record_type, :record_id, :lesson_number, :title, :snippet, keyword_init: true) do
    def type_label = I18n.t("search.types.#{record_type}", default: record_type)

    # Everything indexed lives inside a lesson, so results link to the lesson.
    def lesson? = record_type == "Lesson"
  end

  def initialize(query, include_unpublished: false)
    @query = query.to_s
    @include_unpublished = include_unpublished
  end

  def blank?
    match_expression.blank?
  end

  def results
    return [] if blank?

    rows = ApplicationRecord.connection.select_all(sanitized_sql, "Search")
    rows.filter_map do |row|
      next if hidden_lesson_numbers.include?(row["lesson_number"])

      Result.new(
        record_type: row["record_type"],
        record_id: row["record_id"],
        lesson_number: row["lesson_number"],
        title: row["title"],
        snippet: row["snippet"]
      )
    end
  end

  private

  # Content belonging to unpublished (draft) lessons is hidden from learners.
  # Admins pass include_unpublished: true to search everything.
  def hidden_lesson_numbers
    return @hidden_lesson_numbers if defined?(@hidden_lesson_numbers)
    @hidden_lesson_numbers = @include_unpublished ? [] : Lesson.where(published: false).pluck(:number)
  end

  # Turn free-form user input into a safe FTS5 MATCH expression. Each word is
  # quoted (neutralising FTS operators like AND/OR/NEAR and punctuation) and
  # given a trailing `*` so partial words match as the user types.
  def match_expression
    @query.scan(/[[:word:]]+/).map { |token| %("#{token}"*) }.join(" ")
  end

  def sanitized_sql
    ApplicationRecord.sanitize_sql_array([
      <<~SQL,
        SELECT record_type,
               record_id,
               lesson_number,
               title,
               snippet(search_documents, 4, ?, ?, '…', 12) AS snippet
        FROM search_documents
        WHERE search_documents MATCH ?
          AND record_type IN (?)
        ORDER BY rank
        LIMIT ?
      SQL
      HIGHLIGHT_OPEN,
      HIGHLIGHT_CLOSE,
      match_expression,
      TYPES,
      MAX_RESULTS
    ])
  end
end
