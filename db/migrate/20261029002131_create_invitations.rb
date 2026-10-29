class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.string :token, null: false, index: { unique: true }
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.datetime :accepted_at
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
