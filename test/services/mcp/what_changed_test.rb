require "test_helper"

class Mcp::WhatChangedTest < ActiveSupport::TestCase
  Admin = Struct.new(:email_address)

  def run_tool(**args)
    res = Mcp::Tools::WhatChanged.call(server_context: { user: Admin.new("darren@example.com") }, **args)
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  setup do
    CourseProposal.delete_all
    @old = CourseProposal.capture("old turf idea", origin: "darren").tap { |p| p.created_at = 30.days.ago; p.save! }
    @new = CourseProposal.capture("weather in Erris", origin: "darren").tap(&:save!)
  end

  test "lists new proposals and what is waiting, oldest first" do
    _, body = run_tool
    assert_equal [ @new.id ], body["new_proposals"].map { |p| p["id"] }
    assert_equal 2, body["waiting"]["open"]
    assert_equal [ @old.id, @new.id ], body["waiting"]["longest_waiting"].map { |p| p["id"] }
  end

  test "lists decisions since the date with who made them" do
    @old.decide!("dismiss", by: "seosamh")
    _, body = run_tool
    decided = body["decided"].sole
    assert_equal [ @old.id, "dismissed", "seosamh" ], decided.values_at("id", "status", "decided_by")
    assert_equal 1, body["waiting"]["open"]
  end

  test "lists other people's comments but not the caller's own" do
    @old.proposal_comments.create!(author: "seosamh", body: "Maith an smaoineamh")
    @old.proposal_comments.create!(author: "darren", body: "my own note")
    _, body = run_tool
    assert_equal [ "Maith an smaoineamh" ], body["new_comments"].map { |c| c["body"] }
    assert_equal "old turf idea", body["new_comments"].first["proposal_title"]
  end

  test "lists new evidence with the quote verbatim" do
    @old.proposal_evidence.create!(source: "Erris p. 40", quote: " Tá sé fliuch ")
    _, body = run_tool
    assert_equal [ "Erris p. 40", " Tá sé fliuch " ], body["new_evidence"].sole.values_at("source", "quote")
  end

  test "since widens or narrows the window" do
    @old.proposal_comments.create!(author: "seosamh", body: "old comment").update_columns(created_at: 10.days.ago)
    _, body = run_tool
    assert_empty body["new_comments"]
    _, body = run_tool(since: 40.days.ago.to_date.iso8601)
    assert_equal [ "old comment" ], body["new_comments"].map { |c| c["body"] }
    assert_equal [ @new.id, @old.id ], body["new_proposals"].map { |p| p["id"] }
  end

  test "rejects an unreadable or future since" do
    assert run_tool(since: "last tuesday-ish").first.error?
    assert run_tool(since: "2026-13-45").first.error?
    assert run_tool(since: 2.days.from_now.iso8601).first.error?
  end

  test "longest waiting is by age, not priority" do
    @new.update!(priority: 5)
    _, body = run_tool
    assert_equal [ @old.id, @new.id ], body["waiting"]["longest_waiting"].map { |p| p["id"] }
  end

  test "leaves out decisions made before since" do
    @old.decide!("dismiss", by: "seosamh")
    @old.update_columns(decided_at: 10.days.ago)
    _, body = run_tool
    assert_empty body["decided"]
  end

  test "reads a time without a zone as Irish time and accepts zones and minutes" do
    travel_to Time.zone.parse("2026-07-20 12:00") do
      _, body = run_tool(since: "2026-07-15T10:00:00")
      assert_equal Time.zone.parse("2026-07-15 10:00").iso8601, body["since"]
      _, body = run_tool(since: "2026-07-15T10:00")
      assert_equal Time.zone.parse("2026-07-15 10:00").iso8601, body["since"]
      _, body = run_tool(since: "2026-07-15T10:00:00Z")
      assert_equal Time.utc(2026, 7, 15, 10).iso8601, Time.iso8601(body["since"]).utc.iso8601
      _, body = run_tool(since: "2026-07-15")
      assert_equal Time.zone.parse("2026-07-15 00:00").iso8601, body["since"]
    end
  end

  test "totals count everything even when a list stops at the limit" do
    (Mcp::Tools::WhatChanged::LIMIT + 1).times { |i| @old.proposal_comments.create!(author: "seosamh", body: "c#{i}") }
    _, body = run_tool
    assert_equal Mcp::Tools::WhatChanged::LIMIT, body["new_comments"].size
    assert_equal Mcp::Tools::WhatChanged::LIMIT + 1, body["totals"]["new_comments"]
  end

  test "with no user every comment is listed" do
    @old.proposal_comments.create!(author: "darren", body: "a note")
    body = JSON.parse(Mcp::Tools::WhatChanged.call(server_context: {}).content.first[:text])
    assert_equal [ "a note" ], body["new_comments"].map { |c| c["body"] }
  end

  test "reads only" do
    assert_no_changes -> { [ CourseProposal.count, ProposalComment.count, ProposalEvidence.count, CourseProposal.maximum(:updated_at) ] } do
      run_tool
    end
  end
end
