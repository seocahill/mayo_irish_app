class CreateSectionProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :section_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.string :section_type, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :section_progresses, [ :user_id, :lesson_id, :section_type ], unique: true, name: "index_section_progresses_uniqueness"
  end
end
