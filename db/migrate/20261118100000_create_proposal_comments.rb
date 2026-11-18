class CreateProposalComments < ActiveRecord::Migration[8.1]
  def change
    create_table :proposal_comments do |t|
      t.references :course_proposal, null: false, foreign_key: true
      t.string :author, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
