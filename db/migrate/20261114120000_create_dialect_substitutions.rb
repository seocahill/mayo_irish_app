class CreateDialectSubstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :dialect_substitutions do |t|
      t.string :other_form, null: false
      t.string :mayo_form, null: false
      t.string :other_source
      t.string :mayo_source
      t.text :note
      t.timestamps
    end
    add_index :dialect_substitutions, :other_form
  end
end
