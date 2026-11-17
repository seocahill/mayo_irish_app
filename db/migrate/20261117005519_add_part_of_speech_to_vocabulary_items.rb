class AddPartOfSpeechToVocabularyItems < ActiveRecord::Migration[8.1]
  def change
    add_column :vocabulary_items, :part_of_speech, :string
  end
end
