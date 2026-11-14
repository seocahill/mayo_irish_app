# The newest "what's new" entry a learner has read (see WhatsNew). Nullable and
# additive: existing rows are left as they are, and nil means "none read yet".
class AddWhatsNewSeenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :whats_new_seen_id, :integer
  end
end
