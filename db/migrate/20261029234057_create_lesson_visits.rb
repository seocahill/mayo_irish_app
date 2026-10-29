class CreateLessonVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true

      t.timestamps
    end
    add_index :lesson_visits, %i[user_id lesson_id], unique: true
  end
end
