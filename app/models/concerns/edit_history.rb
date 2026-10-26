# Include in any model whose edits should show up in a lesson's history (and
# be undoable there). Every change is stored as a PaperTrail version tagged
# with the lesson it belongs to, and `label` says what to call the record:
#
#   class VocabularyItem < ApplicationRecord
#     include EditHistory
#     tracked_in_lesson_history lesson_id: ->(v) { v.lesson_id },
#                               label: ->(v) { v.irish },
#                               only: %i[irish english]
#   end
module EditHistory
  extend ActiveSupport::Concern

  class_methods do
    def tracked_in_lesson_history(lesson_id:, label:, only: nil)
      define_method(:history_lesson_id) { lesson_id.call(self) }
      define_method(:history_label) { label.call(self) }
      has_paper_trail only: only, on: %i[create update destroy], meta: { lesson_id: :history_lesson_id }
    end
  end
end
