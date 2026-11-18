require "test_helper"

class CourseProposalsControllerTest < ActionDispatch::IntegrationTest
  test "admins see an empty state" do
    sign_in_as(users(:admin))
    get course_proposals_path
    assert_response :success
    assert_select "#no-proposals"
  end

  test "admins see proposals, highest priority first" do
    CourseProposal.create!(kind: "gap", title: "Low one", priority: 0)
    CourseProposal.create!(kind: "new_lesson", title: "Weather lesson", rationale: "No weather words", priority: 5)
    sign_in_as(users(:admin))
    get course_proposals_path
    assert_select "#proposals li", 2
    assert_select "#proposals li:first-child", /Weather lesson/
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))
    get course_proposals_path
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get course_proposals_path
    assert_response :redirect
  end

  test "admins capture an idea, kept verbatim" do
    sign_in_as(users(:admin))
    text = "A lesson on the weather,\nespecially the wind in Erris."
    assert_difference -> { CourseProposal.count }, 1 do
      post course_proposals_path, params: { raw_text: text }
    end
    assert_redirected_to course_proposals_path
    idea = CourseProposal.last
    assert_equal text, idea.raw_text
    assert_equal "idea", idea.kind
    assert_equal "captured", idea.status
  end

  test "a blank idea is not saved" do
    sign_in_as(users(:admin))
    assert_no_difference -> { CourseProposal.count } do
      post course_proposals_path, params: { raw_text: "   " }
    end
    assert_redirected_to course_proposals_path
  end

  test "learners cannot capture ideas" do
    sign_in_as(users(:two))
    assert_no_difference -> { CourseProposal.count } do
      post course_proposals_path, params: { raw_text: "hello" }
    end
  end

  test "an over-long idea is rejected" do
    sign_in_as(users(:admin))
    assert_no_difference -> { CourseProposal.count } do
      post course_proposals_path, params: { raw_text: "a" * 2001 }
    end
    assert_equal I18n.t("course_proposals.create.too_long"), flash[:alert]
  end

  test "the idea box and a saved idea's words show on the list" do
    sign_in_as(users(:admin))
    post course_proposals_path, params: { raw_text: "Weather.\nWind in Erris." }
    follow_redirect!
    assert_select "form textarea[name=raw_text]"
    assert_select "#proposals li", /Wind in Erris/
  end

  test "an admin can dismiss, then reopen, a proposal, and it is recorded who decided" do
    proposal = CourseProposal.create!(kind: "gap", title: "Weather")
    sign_in_as(users(:admin))
    patch course_proposal_path(proposal), params: { decision: "dismiss" }
    assert_redirected_to course_proposals_path
    proposal.reload
    assert_equal "dismissed", proposal.status
    assert proposal.decided_by.present?
    assert proposal.decided_at.present?
    patch course_proposal_path(proposal), params: { decision: "reopen" }
    proposal.reload
    assert_equal "proposed", proposal.status
    assert_nil proposal.decided_at
  end

  test "an applied proposal cannot be dismissed" do
    proposal = CourseProposal.create!(kind: "gap", title: "Done", status: "applied")
    sign_in_as(users(:admin))
    patch course_proposal_path(proposal), params: { decision: "dismiss" }
    assert_equal "applied", proposal.reload.status
    get course_proposals_path
    assert_select "#proposals input[name=decision]", 0
  end

  test "deciding never changes the idea's own words" do
    idea = CourseProposal.capture("Wind in Erris", origin: "darren").tap(&:save!)
    sign_in_as(users(:admin))
    patch course_proposal_path(idea), params: { decision: "defer" }
    assert_equal "deferred", idea.reload.status
    assert_equal "Wind in Erris", idea.raw_text
  end

  test "an unknown decision is refused" do
    proposal = CourseProposal.create!(kind: "gap", title: "Weather")
    sign_in_as(users(:admin))
    patch course_proposal_path(proposal), params: { decision: "apply" }
    assert_equal I18n.t("course_proposals.update.unknown"), flash[:alert]
    assert_equal "proposed", proposal.reload.status
  end

  test "learners cannot decide on proposals" do
    proposal = CourseProposal.create!(kind: "gap", title: "Weather")
    sign_in_as(users(:two))
    patch course_proposal_path(proposal), params: { decision: "dismiss" }
    assert_equal "proposed", proposal.reload.status
  end

  test "an admin adds a comment and it shows under the proposal, oldest first" do
    proposal = CourseProposal.create!(kind: "gap", title: "Weather")
    sign_in_as(users(:admin))
    assert_difference -> { proposal.proposal_comments.count }, 1 do
      post course_proposal_comments_path(proposal), params: { body: "Erris has a word for this." }
    end
    follow_redirect!
    assert_select "#comments-#{proposal.id} li", /Erris has a word/
    assert proposal.proposal_comments.last.author.present?
  end

  test "a blank or over-long comment is refused" do
    proposal = CourseProposal.create!(kind: "gap", title: "Weather")
    sign_in_as(users(:admin))
    assert_no_difference -> { ProposalComment.count } do
      post course_proposal_comments_path(proposal), params: { body: "  " }
      post course_proposal_comments_path(proposal), params: { body: "a" * 2001 }
    end
    assert_equal I18n.t("proposal_comments.create.invalid"), flash[:alert]
  end

  test "learners cannot comment" do
    proposal = CourseProposal.create!(kind: "gap", title: "Weather")
    sign_in_as(users(:two))
    assert_no_difference -> { ProposalComment.count } do
      post course_proposal_comments_path(proposal), params: { body: "hi" }
    end
  end

  test "commenting leaves the proposal's status and words alone" do
    idea = CourseProposal.capture("Wind in Erris", origin: "darren").tap(&:save!)
    sign_in_as(users(:admin))
    post course_proposal_comments_path(idea), params: { body: "Good one" }
    assert_equal "captured", idea.reload.status
    assert_equal "Wind in Erris", idea.raw_text
  end
end
