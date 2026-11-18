require "test_helper"

class CourseProposalTest < ActiveSupport::TestCase
  test "validates kind and status" do
    assert_not CourseProposal.new(kind: "nope", title: "x").valid?
    assert_not CourseProposal.new(kind: "gap", title: "x", status: "nope").valid?
    assert CourseProposal.new(kind: "gap", title: "x").valid?
  end

  test "pending excludes decided proposals; ordered puts high priority first" do
    a = CourseProposal.create!(kind: "gap", title: "a", priority: 1)
    CourseProposal.create!(kind: "gap", title: "b", status: "dismissed")
    b = CourseProposal.create!(kind: "gap", title: "c", priority: 3)
    assert_equal [ a, b ].sort_by(&:id), CourseProposal.pending.order(:id).to_a
    assert_equal [ b, a ], CourseProposal.pending.ordered.to_a
  end
end
