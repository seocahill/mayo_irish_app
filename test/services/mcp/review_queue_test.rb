require "test_helper"

class Mcp::ReviewQueueTest < ActiveSupport::TestCase
  def call(**args)
    res = Mcp::Tools::ReviewQueue.call(server_context: {}, **args)
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  def proposal(title, origin: "designer", status: "proposed", priority: 0, at: 1.day.ago, **attrs)
    CourseProposal.create!(kind: "gap", title: title, origin: origin, status: status, priority: priority,
                           created_at: at, **attrs)
  end

  test "people's ideas come before the agent's, then higher priority, then the one waiting longest" do
    proposal("agent, high", priority: 5, at: 3.days.ago)
    proposal("agent, older", at: 5.days.ago)
    proposal("agent, newer", at: 1.day.ago)
    proposal("darren's, newer", origin: "darren", status: "captured", at: 1.hour.ago)
    proposal("darren's, older", origin: "darren", status: "discussing", at: 2.days.ago)

    _, data = call

    assert_equal [ "darren's, older", "darren's, newer", "agent, high", "agent, older", "agent, newer" ],
                 data["next"].map { |p| p["title"] }
    assert_equal [ true, true, false, false, false ], data["next"].map { |p| p["from_a_person"] }
  end

  test "leaves out decided and parked proposals but counts every open one" do
    6.times { |i| proposal("open #{i}") }
    %w[accepted applied edited dismissed deferred].each { |status| proposal("closed #{status}", status: status) }

    _, data = call

    assert_equal 6, data["open_in_all"]
    assert_equal 5, data["next"].size
    assert data["next"].none? { |p| p["title"].start_with?("closed") }
  end

  test "limit is kept between one and five" do
    7.times { |i| proposal("open #{i}") }

    assert_equal 2, call(limit: 2).last["next"].size
    assert_equal 5, call(limit: 50).last["next"].size
    assert_equal 1, call(limit: 0).last["next"].size
    assert_equal 5, call(limit: nil).last["next"].size
  end

  test "each line has a one-line summary and counts its evidence and comments" do
    long = "Learners in Erris need the weather.\n\n" + ("They talk about it all the time. " * 10)
    p = proposal("Weather", rationale: long)
    p.proposal_evidence.create!(source: "Irish of Erris, p. 12")
    2.times { p.proposal_comments.create!(author: "darren", body: "yes") }
    proposal("Just words", origin: "darren", raw_text: "turf  and\nbogs")

    rows = call.last["next"].index_by { |row| row["title"] }

    assert_equal "turf and bogs", rows["Just words"]["summary"]
    summary = rows["Weather"]["summary"]
    assert summary.start_with?("Learners in Erris need the weather. They talk")
    assert_operator summary.length, :<=, CourseProposal::SUMMARY_LENGTH
    assert_not_includes summary, "\n"
    assert_equal [ 1, 2 ], [ rows["Weather"]["evidence"], rows["Weather"]["comments"] ]
    assert_equal p.id, rows["Weather"]["id"]
  end

  test "the summary falls back to the outline and is left out when it only repeats the title" do
    proposal("With outline", outline: "Weather words, then a short story")
    proposal("Bare")
    CourseProposal.capture("A turf lesson", origin: "darren").save!

    rows = call.last["next"].index_by { |row| row["title"] }

    assert_equal "Weather words, then a short story", rows["With outline"]["summary"]
    assert_nil rows["Bare"]["summary"]
    assert_nil rows["A turf lesson"]["summary"]
  end

  test "an empty queue says so plainly" do
    _, data = call

    assert_equal({ "open_in_all" => 0, "next" => [] }, data)
  end

  test "writes nothing" do
    proposal("open")
    assert_no_changes(-> { [ CourseProposal.maximum(:updated_at), CourseProposal.count, ProposalComment.count ] }) { call }
  end
end
