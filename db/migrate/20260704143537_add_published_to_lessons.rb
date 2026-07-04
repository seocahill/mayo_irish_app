# frozen_string_literal: true

class AddPublishedToLessons < ActiveRecord::Migration[8.1]
  def change
    # Existing lessons stay visible (default true); lessons created through the
    # MCP connector start unpublished so they can be reviewed before learners
    # see them.
    add_column :lessons, :published, :boolean, null: false, default: true
    add_index  :lessons, :published
  end
end
