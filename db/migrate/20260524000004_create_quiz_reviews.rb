class CreateQuizReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :quiz_reviews do |t|
      t.references :user,          null: false, foreign_key: true
      t.references :quiz_question, null: false, foreign_key: true
      t.integer  :box,            null: false, default: 1
      t.datetime :due_at
      t.datetime :last_reviewed_at
      t.integer  :times_correct, null: false, default: 0
      t.integer  :times_wrong,   null: false, default: 0

      t.timestamps
    end

    add_index :quiz_reviews, [ :user_id, :quiz_question_id ], unique: true
    add_index :quiz_reviews, [ :user_id, :due_at ]
  end
end
