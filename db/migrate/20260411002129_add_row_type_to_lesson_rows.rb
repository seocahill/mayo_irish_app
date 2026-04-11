class AddRowTypeToLessonRows < ActiveRecord::Migration[8.1]
  def change
    add_column :lesson_rows, :row_type, :string, default: 'data', null: false
  end
end
