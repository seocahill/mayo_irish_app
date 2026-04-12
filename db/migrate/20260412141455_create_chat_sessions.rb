class CreateChatSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_sessions do |t|
      t.references :lesson, null: false, foreign_key: true

      t.timestamps
    end
  end
end
