class CreateRecordingQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_questions do |t|
      t.integer :abairt_recording_id, null: false, index: true
      t.text :question, null: false
      t.text :answer, null: false
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
