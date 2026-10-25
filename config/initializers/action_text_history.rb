# Rich text bodies (lesson notes, grammar, blocks) live in their own table, so
# they get their own versions, filed under the lesson of the record they
# belong to. Only edits are recorded: a body's first write is an edit from
# nothing, and it goes when its record does. Rich text on records without a
# lesson history is left alone.
ActiveSupport.on_load(:action_text_rich_text) do
  has_paper_trail only: :body,
                  on: :update,
                  if: ->(rich_text) { rich_text.record.respond_to?(:history_lesson_id) },
                  meta: { lesson_id: ->(rich_text) { rich_text.record.history_lesson_id } }

  def history_label = record.history_label
end
