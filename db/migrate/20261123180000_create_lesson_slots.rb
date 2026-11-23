class CreateLessonSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_slots do |t|
      t.references :lesson, null: false, foreign_key: true, index: false
      t.string :slot_type, null: false
      t.text :spec, null: false
      t.string :status, null: false, default: "open"
      t.string :created_by
      t.string :removed_by
      t.datetime :removed_at
      t.timestamps
    end
    add_index :lesson_slots, %i[lesson_id status]
  end
end
