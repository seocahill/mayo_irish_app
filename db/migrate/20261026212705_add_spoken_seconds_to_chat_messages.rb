class AddSpokenSecondsToChatMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_messages, :spoken_seconds, :integer
  end
end
