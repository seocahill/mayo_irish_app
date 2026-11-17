class AddFormProvenanceAndDismissals < ActiveRecord::Migration[8.1]
  def change
    add_column :vocabulary_items, :plural_source_entry_id, :integer
    add_column :vocabulary_items, :genitive_source_entry_id, :integer

    create_table :form_suggestion_dismissals do |t|
      t.references :vocabulary_item, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :form, null: false
      t.timestamps
    end
    add_index :form_suggestion_dismissals, %i[vocabulary_item_id kind form], unique: true, name: "index_form_dismissals_uniqueness"
  end
end
