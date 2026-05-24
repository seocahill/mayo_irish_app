class AddAudioUrlToVocabularyItems < ActiveRecord::Migration[8.1]
  def change
    add_column :vocabulary_items, :audio_url, :string
  end
end
