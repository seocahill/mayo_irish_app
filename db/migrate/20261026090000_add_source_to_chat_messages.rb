class AddSourceToChatMessages < ActiveRecord::Migration[8.1]
  def change
    # Which AI wrote a comhrá reply ("abair" or "openai"), to compare them.
    add_column :chat_messages, :source, :string
  end
end
