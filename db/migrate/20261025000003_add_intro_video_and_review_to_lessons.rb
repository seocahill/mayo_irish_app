class AddIntroVideoAndReviewToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :intro_video_url, :text
    add_column :lessons, :intro_video_transcript, :text
    add_column :lessons, :reviewed_at, :datetime
    add_reference :lessons, :reviewed_by, foreign_key: { to_table: :users }
  end
end
