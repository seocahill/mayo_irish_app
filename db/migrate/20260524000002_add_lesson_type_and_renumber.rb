class AddLessonTypeAndRenumber < ActiveRecord::Migration[8.1]
  def up
    add_column :lessons, :lesson_type, :string, default: "curriculum", null: false

    # Temporarily disable the unique index so we can renumber without collisions
    remove_index :lessons, :number
    add_index    :lessons, :number, unique: false, name: "index_lessons_on_number_tmp"

    # Set lesson_type before renumbering
    execute "UPDATE lessons SET lesson_type = 'curriculum'    WHERE number BETWEEN 0   AND 99"
    execute "UPDATE lessons SET lesson_type = 'thematic_vocab' WHERE number BETWEEN 100 AND 199"
    execute "UPDATE lessons SET lesson_type = 'dias_material'  WHERE number BETWEEN 200 AND 299"

    # Renumber thematic_vocab: 101-177 → 37-113 (subtract 64; no collision with 0-36)
    execute "UPDATE lessons SET number = number - 64, position = position - 64 WHERE number BETWEEN 100 AND 199"

    # Renumber dias_material: 201-218 → 114-131 (subtract 87; no collision with 0-113)
    execute "UPDATE lessons SET number = number - 87, position = position - 87 WHERE number BETWEEN 200 AND 299"

    remove_index :lessons, name: "index_lessons_on_number_tmp"
    add_index    :lessons, :number, unique: true
    add_index    :lessons, :lesson_type
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
