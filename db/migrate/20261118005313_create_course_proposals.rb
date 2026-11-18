class CreateCourseProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :course_proposals do |t|
      t.string :origin, null: false, default: "designer"
      t.string :kind, null: false
      t.string :status, null: false, default: "proposed"
      t.string :title, null: false
      t.text :rationale
      t.text :outline
      t.text :raw_text
      t.integer :priority, null: false, default: 0
      t.timestamps
    end
    add_index :course_proposals, :status
  end
end
