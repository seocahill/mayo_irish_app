class CreateQuizQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_questions do |t|
      t.references :lesson, null: false, foreign_key: true
      t.references :source, polymorphic: true, null: false
      t.string :direction, null: false
      t.text   :prompt,    null: false
      t.string :answer,    null: false
      t.json   :distractors, null: false, default: []

      t.timestamps
    end

    add_index :quiz_questions, [ :source_type, :source_id, :direction ],
              unique: true, name: "index_quiz_questions_uniqueness"
  end
end
