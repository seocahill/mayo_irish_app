# Additive: FSRS scheduling state next to the Leitner box (which is kept).
# Existing rows are seeded from their box so learners' schedules aren't reset.
class AddFsrsToQuizReviews < ActiveRecord::Migration[8.0]
  def up
    add_column :quiz_reviews, :stability, :float, null: false, default: 0.0
    add_column :quiz_reviews, :difficulty, :float, null: false, default: 0.0
    add_column :quiz_reviews, :fsrs_state, :integer, null: false, default: 0

    # state 2 = review, 3 = relearning; stability = the days the box used to wait.
    execute <<~SQL
      UPDATE quiz_reviews SET
        fsrs_state = CASE WHEN box = 1 THEN 3 ELSE 2 END,
        difficulty = 5.0,
        stability = CASE box WHEN 1 THEN 0.5 WHEN 2 THEN 1.0 WHEN 3 THEN 3.0 WHEN 4 THEN 7.0 ELSE 21.0 END
    SQL
    add_index :quiz_reviews, [ :user_id, :stability ]
  end

  def down
    remove_index :quiz_reviews, [ :user_id, :stability ]
    remove_column :quiz_reviews, :fsrs_state
    remove_column :quiz_reviews, :difficulty
    remove_column :quiz_reviews, :stability
  end
end
