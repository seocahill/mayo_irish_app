class CreateNativeQuestions < ActiveRecord::Migration[8.1]
  def change
    # A learner's spoken question to a native speaker. The recordings live on
    # Abairt; this keeps who asked, about which lesson, and where things stand.
    create_table :native_questions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, foreign_key: true
      t.integer :abairt_question_id, null: false
      t.string :status, null: false, default: "waiting"
      t.string :audio_url
      t.string :answer_audio_url
      t.datetime :answered_at
      t.datetime :answer_seen_at
      t.timestamps
    end
    add_index :native_questions, :abairt_question_id, unique: true
  end
end
