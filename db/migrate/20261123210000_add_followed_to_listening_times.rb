# The learner's own word on whether they followed a whole recording: true, false
# (not yet), or nil when they haven't said. Nullable, so no existing row changes.
class AddFollowedToListeningTimes < ActiveRecord::Migration[8.1]
  def change
    add_column :listening_times, :followed, :boolean
  end
end
