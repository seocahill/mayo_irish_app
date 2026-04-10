class CreateLessonRows < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_rows do |t|
      t.integer :lesson_id
      t.string :section
      t.integer :position
      t.text :col_1
      t.text :col_2
      t.text :col_3

      t.timestamps
    end
    add_index :lesson_rows, [ :lesson_id, :section, :position ]
    add_foreign_key :lesson_rows, :lessons
  end
end
