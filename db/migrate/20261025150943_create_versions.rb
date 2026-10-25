# Edit history for lesson content (see PaperTrail). `lesson_id` lets a lesson's
# history be listed in one query even for its vocabulary, grammar and blocks.
class CreateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :versions do |t|
      t.string :whodunnit
      t.datetime :created_at
      t.bigint :item_id, null: false
      t.string :item_type, null: false
      t.string :event, null: false
      t.text :object
      t.text :object_changes
      t.integer :lesson_id
    end
    add_index :versions, %i[item_type item_id]
    add_index :versions, %i[lesson_id created_at]
  end
end
