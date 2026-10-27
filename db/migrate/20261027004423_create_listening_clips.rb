class CreateListeningClips < ActiveRecord::Migration[8.1]
  def change
    # Short phrases from Abairt in which a Mayo speaker uses a course word, for
    # learners to listen to. An editor can hide one that isn't suitable.
    create_table :listening_clips do |t|
      t.references :vocabulary_item, null: false, foreign_key: true
      t.integer :abairt_entry_id, null: false, index: { unique: true }
      t.string :irish, null: false
      t.string :english, null: false
      t.string :audio_url, null: false
      t.string :speaker_name
      t.string :speaker_dialect
      t.integer :word_count, null: false
      t.text :heard
      t.string :status, null: false, default: "listed"
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end

    # A learner having listened to a clip, and whether they understood it.
    create_table :listens do |t|
      t.references :user, null: false, foreign_key: true
      t.references :listening_clip, null: false, foreign_key: true
      t.boolean :understood, null: false
      t.timestamps
    end
    add_index :listens, %i[user_id listening_clip_id], unique: true

    # When Abairt was last searched for clips of the word.
    add_column :vocabulary_items, :clips_searched_at, :datetime
  end
end
