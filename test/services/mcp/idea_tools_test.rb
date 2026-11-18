require "test_helper"

class Mcp::IdeaToolsTest < ActiveSupport::TestCase
  Admin = Struct.new(:email_address)

  test "capture_idea stores the words verbatim and adds one proposal" do
    text = "A lesson on the weather in Erris, ask about  “tá sé fliuch”"
    assert_difference -> { CourseProposal.count }, 1 do
      res = Mcp::Tools::CaptureIdea.call(text: text, server_context: { user: Admin.new("darren@example.com") })
      assert_not res.error?
    end
    p = CourseProposal.order(:id).last
    assert_equal text, p.raw_text
    assert_equal "darren", p.origin
    assert_equal "captured", p.status
  end

  test "capture_idea rejects blank text and over-long text" do
    ctx = { user: Admin.new("a@b.c") }
    assert_no_difference -> { CourseProposal.count } do
      assert Mcp::Tools::CaptureIdea.call(text: "", server_context: ctx).error?
      assert Mcp::Tools::CaptureIdea.call(text: "x" * 2001, server_context: ctx).error?
    end
  end

  test "list_ideas shows open ideas only" do
    open = CourseProposal.capture("open one", origin: "x"); open.save!
    gone = CourseProposal.capture("dismissed one", origin: "x"); gone.status = "dismissed"; gone.save!
    body = Mcp::Tools::ListIdeas.call(server_context: {}).content.first[:text]
    assert_includes body, "open one"
    assert_not_includes body, "dismissed one"
  end

  test "server exposes both tools" do
    assert_includes Mcp::Server::TOOLS, Mcp::Tools::CaptureIdea
    assert_includes Mcp::Server::TOOLS, Mcp::Tools::ListIdeas
  end
end
