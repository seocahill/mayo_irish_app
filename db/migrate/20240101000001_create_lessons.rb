class CreateLessons < ActiveRecord::Migration[8.0]
  def change
    create_table :lessons do |t|
      t.integer :number, null: false
      t.string :title, null: false
      t.text :vocabulary_notes
      t.text :grammar
      t.text :texts
      t.text :exercises
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :lessons, :number, unique: true
    add_index :lessons, :position
  end
end
