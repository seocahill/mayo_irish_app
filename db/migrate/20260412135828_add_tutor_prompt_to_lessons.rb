class AddTutorPromptToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :tutor_prompt, :text
  end
end
