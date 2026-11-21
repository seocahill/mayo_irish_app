class AddSourceToVocabularyItems < ActiveRecord::Migration[8.1]
  def change
    add_column :vocabulary_items, :source, :string
  end
end
