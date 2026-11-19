class CreateProposalEvidence < ActiveRecord::Migration[8.1]
  def change
    create_table :proposal_evidence do |t|
      t.references :course_proposal, null: false, foreign_key: true
      t.string :source, null: false
      t.text :quote
      t.string :audio_url
      t.timestamps
    end
  end
end
