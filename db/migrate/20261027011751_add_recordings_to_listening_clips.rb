class AddRecordingsToListeningClips < ActiveRecord::Migration[8.1]
  def change
    # The whole Abairt recording a clip was cut from, and where in it, so a
    # learner can go on to hear the conversation around it.
    add_column :listening_clips, :abairt_recording_id, :integer
    add_column :listening_clips, :abairt_recording_title, :string
    add_column :listening_clips, :starts_at, :float
    add_index :listening_clips, :abairt_recording_id

    # How long a learner has listened to a whole recording.
    create_table :listening_times do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :abairt_recording_id, null: false
      t.integer :seconds, null: false, default: 0
      t.timestamps
    end
    add_index :listening_times, %i[user_id abairt_recording_id], unique: true
  end
end
