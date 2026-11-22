class CreateSpeakingDays < ActiveRecord::Migration[8.1]
  def change
    create_table :speaking_days do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.date :day, null: false
      t.integer :seconds, null: false, default: 0
      t.timestamps
    end
    add_index :speaking_days, [ :user_id, :day ], unique: true
  end
end
