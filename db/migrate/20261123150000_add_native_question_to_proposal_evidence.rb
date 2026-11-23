# Links a piece of proposal evidence to the learner's question it came from.
# Nullable and new rows only: existing evidence is left as it is.
class AddNativeQuestionToProposalEvidence < ActiveRecord::Migration[8.1]
  def change
    add_reference :proposal_evidence, :native_question, null: true, index: true
  end
end
