# Include in any model whose content should appear in the global search index
# (the `search_documents` FTS5 table). Each model declares what to index with:
#
#   class VocabularyItem < ApplicationRecord
#     include Searchable
#     searchable title: ->(v) { "#{v.irish} — #{v.english}" },
#                body:  ->(v) { [v.irish, v.english, v.phonetic, v.plural, v.notes] },
#                lesson_number: ->(v) { v.lesson.number }
#   end
#
# The record is (re)indexed after every save and removed after destroy, so the
# index stays in step with edits automatically. `body` may return a string or
# an array of strings (blanks are ignored); rich text should be passed as
# `field.to_plain_text`.
module Searchable
  extend ActiveSupport::Concern

  # Registry of every model that mixes Searchable in, so the index can be
  # rebuilt from scratch (seeds / rake task) without listing them by hand.
  mattr_accessor :registered_models, default: []

  class_methods do
    def searchable(title:, body:, lesson_number: nil)
      @search_title = title
      @search_body = body
      @search_lesson_number = lesson_number

      Searchable.registered_models |= [self]

      after_save_commit :sync_search_document
      after_destroy_commit :remove_search_document
    end

    attr_reader :search_title, :search_body, :search_lesson_number

    # Rebuild this model's slice of the index. Used when backfilling data that
    # was loaded without callbacks (seeds, fixtures, bulk imports).
    def reindex_all
      find_each(&:sync_search_document)
    end
  end

  def sync_search_document
    SearchIndex.upsert(self)
  end

  def remove_search_document
    SearchIndex.delete(self)
  end

  # Values pulled from the DSL procs for this record.
  def search_title
    resolve_search_value(self.class.search_title)
  end

  def search_body
    Array(resolve_search_value(self.class.search_body))
      .flatten
      .map { |v| v.to_s.strip }
      .reject(&:blank?)
      .join("\n")
  end

  def search_lesson_number
    self.class.search_lesson_number && resolve_search_value(self.class.search_lesson_number)
  end

  private

  def resolve_search_value(spec)
    case spec
    when Proc then spec.call(self)
    when Symbol then public_send(spec)
    else spec
    end
  end
end
