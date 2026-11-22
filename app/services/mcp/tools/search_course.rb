module Mcp
  module Tools
    # Read-only: the site's full-text search, for a designer working from a
    # chat app. Covers the course itself; Abairt and the monographs are not in it.
    class SearchCourse < Base
      DEFAULT_LIMIT = 20

      tool_name "search_course"
      description "Search the whole course (lessons, vocabulary, phrases, grammar rules and sections, " \
                  "lesson text) for Irish or English words, fadas optional, partial words match. " \
                  "Returns each match's type, lesson number, title and a short snippet with the " \
                  "matched words in **bold**, best first, and total (counted up to #{Search::MAX_RESULTS}; truncated " \
                  "is true when there may be more). Draft lessons are included for admins. " \
                  "Returns the course's own text only; Abairt and the monographs are not searched. Read-only."
      annotations(
        title: "Search the course",
        read_only_hint: true,
        destructive_hint: false,
        idempotent_hint: true,
        open_world_hint: false
      )
      input_schema(
        properties: {
          query: { type: "string", description: "Words to find, as typed (Irish or English)" },
          limit: { type: "integer", minimum: 1, maximum: Search::MAX_RESULTS,
                   description: "How many results (default #{DEFAULT_LIMIT}, max #{Search::MAX_RESULTS})" }
        },
        required: [ "query" ]
      )

      def self.call(query:, server_context:, limit: nil)
        search = Search.new(query, include_unpublished: server_context[:user].try(:admin?) == true)
        return error("Give a word or words to search for") if search.blank?

        count = (limit || DEFAULT_LIMIT).to_i.clamp(1, Search::MAX_RESULTS)
        results = search.results
        json_response(
          query: query.to_s,
          total: results.size,
          # The search stops at MAX_RESULTS; say so rather than let total look exact.
          truncated: results.size >= Search::MAX_RESULTS,
          results: results.first(count).map do |r|
            { type: r.record_type, id: r.record_id, lesson_number: r.lesson_number,
              title: r.title, snippet: bold(r.snippet) }
          end
        )
      end

      class << self
        private

        def bold(snippet)
          snippet.to_s.gsub(Search::HIGHLIGHT_OPEN, "**").gsub(Search::HIGHLIGHT_CLOSE, "**")
        end
      end
    end
  end
end
