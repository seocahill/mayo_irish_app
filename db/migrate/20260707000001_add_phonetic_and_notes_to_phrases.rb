# frozen_string_literal: true

class AddPhoneticAndNotesToPhrases < ActiveRecord::Migration[8.1]
  def change
    # Dialect idioms need pronunciation on every entry, so mirror the columns
    # vocabulary_items already carries: a short phonetic string and free-text notes.
    add_column :phrases, :phonetic, :string
    add_column :phrases, :notes, :text
  end
end
