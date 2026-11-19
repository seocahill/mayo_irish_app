require "test_helper"

class ProposalEvidenceTest < ActiveSupport::TestCase
  setup { @proposal = CourseProposal.create!(kind: "gap", title: "Weather") }

  test "needs a source; quote and audio are optional" do
    assert_not @proposal.proposal_evidence.build(source: " ").valid?
    assert @proposal.proposal_evidence.build(source: "Erris §12, p. 40").valid?
  end

  test "audio must be an http link" do
    assert_not @proposal.proposal_evidence.build(source: "x", audio_url: "javascript:alert(1)").valid?
    assert_not @proposal.proposal_evidence.build(source: "x", audio_url: "not a url").valid?
    assert @proposal.proposal_evidence.build(source: "x", audio_url: "https://abairt.ie/a.mp3").valid?
  end

  test "evidence comes oldest first and goes with its proposal" do
    @proposal.proposal_evidence.create!(source: "b", created_at: 1.hour.ago)
    @proposal.proposal_evidence.create!(source: "a", created_at: 2.hours.ago)
    assert_equal %w[a b], @proposal.proposal_evidence.map(&:source)
    assert_difference -> { ProposalEvidence.count }, -2 do
      @proposal.destroy
    end
  end
end
