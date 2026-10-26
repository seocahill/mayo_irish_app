class CreateReviewLogs < ActiveRecord::Migration[8.1]
  # One row per answered quiz question. QuizReview only keeps the latest state,
  # so this history is what a better scheduler (e.g. FSRS) would be fitted on.
  def change
    create_table :review_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz_question, foreign_key: { on_delete: :nullify }
      t.string :prompt, null: false
      t.boolean :correct, null: false
      t.integer :box_before, null: false
      t.integer :box_after, null: false
      t.datetime :answered_at, null: false
      t.timestamps
    end

    add_index :review_logs, [ :user_id, :answered_at ]
  end
end
