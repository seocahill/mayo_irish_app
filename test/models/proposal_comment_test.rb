require "test_helper"

class ProposalCommentTest < ActiveSupport::TestCase
  setup { @proposal = CourseProposal.create!(kind: "gap", title: "Weather") }

  test "needs an author and a body of at most 2000 characters" do
    assert_not @proposal.proposal_comments.build(author: "a", body: " ").valid?
    assert_not @proposal.proposal_comments.build(author: "", body: "x").valid?
    assert_not @proposal.proposal_comments.build(author: "a", body: "x" * 2001).valid?
    assert @proposal.proposal_comments.build(author: "a", body: "x").valid?
  end

  test "comments come oldest first and go with their proposal" do
    @proposal.proposal_comments.create!(author: "a", body: "second", created_at: 1.hour.ago)
    @proposal.proposal_comments.create!(author: "a", body: "first", created_at: 2.hours.ago)
    assert_equal %w[first second], @proposal.proposal_comments.map(&:body)
    assert_difference -> { ProposalComment.count }, -2 do
      @proposal.destroy
    end
  end
end
