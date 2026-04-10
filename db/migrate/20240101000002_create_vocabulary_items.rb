class CreateVocabularyItems < ActiveRecord::Migration[8.0]
  def change
    create_table :vocabulary_items do |t|
      t.references :lesson, null: false, foreign_key: true
      t.string :irish, null: false
      t.string :phonetic
      t.string :plural
      t.string :gender, default: 'm'   # 'm' or 'f'
      t.string :english, null: false
      t.text :notes
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :vocabulary_items, [:lesson_id, :position]
  end
end
