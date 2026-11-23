# The part of a day's listening that was short clips rather than whole
# recordings, so the lifetime total can add it to ListeningTime (which only
# knows whole recordings). Defaults to 0: existing days read as before.
class AddClipSecondsToListeningDays < ActiveRecord::Migration[8.1]
  def change
    add_column :listening_days, :clip_seconds, :integer, null: false, default: 0
  end
end
