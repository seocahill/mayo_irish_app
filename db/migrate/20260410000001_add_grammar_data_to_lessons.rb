class AddGrammarDataToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :grammar_data, :text
  end
end
