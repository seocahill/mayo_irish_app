require "test_helper"

class WhatsNewTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @user.update_columns(created_at: Time.utc(2026, 1, 1), whats_new_seen_id: nil)
  end

  test "lists notes newest first" do
    assert_equal [ 3, 2, 1 ], WhatsNew.current.entries.map(&:id)
    assert_equal 3, WhatsNew.current.latest_id
  end

  test "a learner sees the notes they haven't read" do
    assert_equal [ 3, 2, 1 ], @user.whats_new_unseen.map(&:id)

    @user.mark_whats_new_seen(2)

    assert_equal [ 3 ], @user.reload.whats_new_unseen.map(&:id)
  end

  test "reading never moves backwards" do
    @user.mark_whats_new_seen(3)
    @user.mark_whats_new_seen(1)

    assert_equal 3, @user.reload.whats_new_seen_id
    assert_empty @user.whats_new_unseen
  end

  test "ignores a missing or junk marker" do
    @user.mark_whats_new_seen(nil)
    @user.mark_whats_new_seen("nope")

    assert_nil @user.reload.whats_new_seen_id
  end

  test "a learner never sees notes from before they joined" do
    @user.update_columns(created_at: Time.utc(2026, 7, 15))

    assert_equal [ 3 ], @user.whats_new_unseen.map(&:id)
  end

  test "marking as read leaves the rest of the account alone" do
    assert_no_changes -> { @user.reload.attributes.except("whats_new_seen_id") } do
      @user.mark_whats_new_seen(3)
    end
  end

  test "an empty file has no notes" do
    notes = WhatsNew.new([])

    assert_empty notes.entries
    assert_equal 0, notes.latest_id
    assert_empty notes.unseen_for(@user)
  end

  test "uses the shipped notes when no path is configured" do
    configured = Rails.configuration.x.whats_new_path
    # What an unset config.x entry looks like.
    Rails.configuration.x.whats_new_path = ActiveSupport::OrderedOptions.new

    assert_equal WhatsNew.load(WhatsNew::DEFAULT_PATH).entries, WhatsNew.current.entries
  ensure
    Rails.configuration.x.whats_new_path = configured
  end

  test "a broken notes file shows nothing instead of raising" do
    path = Rails.root.join("tmp/whats_new_broken_#{Process.pid}.yml")
    File.write(path, "- id: 1\n  date: 2026-01-01\n  title: No body here\n")
    Rails.configuration.x.whats_new_path = path

    assert_empty WhatsNew.current.entries
  ensure
    Rails.configuration.x.whats_new_path = Rails.root.join("test/test_helpers/whats_new.yml")
    File.delete(path) if path && File.exist?(path)
  end

  # The real notes file, which agents add to with every visible change.
  test "the shipped notes are well formed" do
    entries = WhatsNew.load(WhatsNew::DEFAULT_PATH).entries

    assert_equal entries.map(&:id).uniq, entries.map(&:id), "ids must be unique"
    assert entries.all? { |e| e.id.is_a?(Integer) && e.id.positive? }
    assert entries.all? { |e| e.date.is_a?(Date) }, "dates must be YYYY-MM-DD"
    assert entries.all? { |e| e.title.present? && e.body.present? }
    entries.sort_by(&:id).each_cons(2) do |older, newer|
      assert_operator newer.date, :>=, older.date, "note #{newer.id} is dated before note #{older.id}"
    end
  end

  test "every path in the shipped notes is a real page" do
    paths = WhatsNew.load(WhatsNew::DEFAULT_PATH).entries.filter_map(&:path)

    broken = paths.reject do |path|
      Rails.application.routes.recognize_path(path)
    rescue ActionController::RoutingError
      false
    end

    assert_empty broken, "not routes: #{broken.join(', ')}"
  end
end
