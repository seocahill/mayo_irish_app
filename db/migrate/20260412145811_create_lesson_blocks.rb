class CreateLessonBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_blocks do |t|
      t.references :lesson, null: false, foreign_key: true
      t.string :block_type
      t.integer :position
      t.string :caption
      t.string :url

      t.timestamps
    end
  end
end
