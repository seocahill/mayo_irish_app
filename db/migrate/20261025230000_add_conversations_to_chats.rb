class AddConversationsToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_sessions, :kind, :string, null: false, default: "tutor"
    add_index :chat_sessions, %i[user_id lesson_id kind]

    add_column :chat_messages, :english, :text
    add_column :chat_messages, :note, :text
    add_column :chat_messages, :flagged_at, :datetime
    add_index :chat_messages, :flagged_at
  end
end
