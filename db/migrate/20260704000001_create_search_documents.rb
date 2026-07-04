class CreateSearchDocuments < ActiveRecord::Migration[8.1]
  def up
    # A single FTS5 index over all searchable content across the app.
    #
    # `remove_diacritics 2` folds fadas away, so an English speaker typing
    # "failte" matches "fáilte" and vice-versa — search works for both
    # English and Irish (Gaeilge) without the user worrying about accents.
    #
    # record_type / record_id / lesson_number are stored but not tokenised
    # (UNINDEXED); title and body are the searchable columns.
    create_virtual_table :search_documents, :fts5, [
      "record_type UNINDEXED",
      "record_id UNINDEXED",
      "lesson_number UNINDEXED",
      "title",
      "body",
      'tokenize = "unicode61 remove_diacritics 2"'
    ]
  end

  def down
    drop_table :search_documents
  end
end
