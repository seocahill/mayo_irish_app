require "test_helper"

class Mcp::ProposalToolsTest < ActiveSupport::TestCase
  Admin = Struct.new(:email_address)

  setup { @p = CourseProposal.capture("turf cutting lesson", origin: "darren").tap(&:save!) }

  test "get_proposal returns words and discussion" do
    @p.proposal_comments.create!(author: "a", body: "good idea")
    body = Mcp::Tools::GetProposal.call(id: @p.id, server_context: {}).content.first[:text]
    assert_includes body, "turf cutting lesson"
    assert_includes body, "good idea"
  end

  test "get_proposal errors on unknown id" do
    assert Mcp::Tools::GetProposal.call(id: 0, server_context: {}).error?
  end

  test "comment_on_proposal adds one comment and leaves status alone" do
    assert_difference -> { ProposalComment.count }, 1 do
      res = Mcp::Tools::CommentOnProposal.call(id: @p.id, text: " tá sé go maith ", server_context: { user: Admin.new("darren@x.ie") })
      assert_not res.error?
    end
    c = @p.proposal_comments.last
    assert_equal "darren", c.author
    assert_equal "tá sé go maith", c.body
    assert_equal "captured", @p.reload.status
  end

  test "comment_on_proposal rejects blank, long and unknown" do
    ctx = { user: nil }
    assert_no_difference -> { ProposalComment.count } do
      assert Mcp::Tools::CommentOnProposal.call(id: @p.id, text: " ", server_context: ctx).error?
      assert Mcp::Tools::CommentOnProposal.call(id: @p.id, text: "x" * 2001, server_context: ctx).error?
      assert Mcp::Tools::CommentOnProposal.call(id: 0, text: "hi", server_context: ctx).error?
    end
  end

  test "add_proposal_evidence stores the quote verbatim and get_proposal returns it" do
    assert_difference -> { ProposalEvidence.count }, 1 do
      res = Mcp::Tools::AddProposalEvidence.call(id: @p.id, source: "Erris p. 40", quote: " Tá sé fliuch ",
                                                 audio_url: "https://abairt.ie/a.mp3", server_context: {})
      assert_not res.error?
    end
    body = Mcp::Tools::GetProposal.call(id: @p.id, server_context: {}).content.first[:text]
    assert_includes body, "Erris p. 40"
    assert_includes body, " Tá sé fliuch "
    assert_equal "captured", @p.reload.status
  end

  test "add_proposal_evidence rejects blank source, bad link and unknown proposal" do
    assert_no_difference -> { ProposalEvidence.count } do
      assert Mcp::Tools::AddProposalEvidence.call(id: @p.id, source: " ", server_context: {}).error?
      assert Mcp::Tools::AddProposalEvidence.call(id: @p.id, source: "x", audio_url: "ftp://x", server_context: {}).error?
      assert Mcp::Tools::AddProposalEvidence.call(id: 0, source: "x", server_context: {}).error?
    end
  end
end
