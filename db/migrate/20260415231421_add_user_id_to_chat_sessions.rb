class AddUserIdToChatSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :chat_sessions, :user, null: true, foreign_key: true
  end
end
