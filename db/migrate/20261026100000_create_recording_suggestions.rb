class CreateRecordingSuggestions < ActiveRecord::Migration[8.1]
  def change
    # Real Mayo recordings from Abairt suggested for a vocabulary word, waiting
    # for an editor to approve or reject them.
    create_table :recording_suggestions do |t|
      t.references :vocabulary_item, null: false, foreign_key: true
      t.integer :abairt_entry_id, null: false
      t.string :irish, null: false
      t.string :english
      t.string :audio_url, null: false
      t.string :speaker_name
      t.string :speaker_dialect
      t.text :heard
      t.boolean :check_passed, null: false, default: false
      t.string :status, null: false, default: "pending"
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :recording_suggestions, %i[vocabulary_item_id abairt_entry_id], unique: true

    # Who is speaking in the word's recording, when it isn't the course's own,
    # and when Abairt was last searched for one.
    add_column :vocabulary_items, :audio_credit, :string
    add_column :vocabulary_items, :recordings_searched_at, :datetime
  end
end
