class AddGenitiveToVocabularyItems < ActiveRecord::Migration[8.1]
  def change
    add_column :vocabulary_items, :genitive, :string
  end
end
