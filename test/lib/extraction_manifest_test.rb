require "test_helper"
require "tmpdir"
require_relative "../../lib/extraction/manifest"

class ExtractionManifestTest < ActiveSupport::TestCase
  setup do
    @dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@dir, "scans", "a"))
    File.write(File.join(@dir, "scans", "a", "one.docx"), "hello")
    File.write(File.join(@dir, "scans", "a", "notes.txt"), "ignored")
    @manifest = Extraction::Manifest.new(root: @dir)
  end

  teardown { FileUtils.remove_entry(@dir) }

  def write_queue(units)
    File.write(File.join(@dir, "extraction_queue.yml"), { "units" => units }.to_yaml)
  end

  test "lists only source files and marks them new" do
    entries = @manifest.write!
    assert_equal [ "scans/a/one.docx" ], entries.map { |e| e["path"] }
    assert_equal "new", entries.first["status"]
    assert_equal Digest::SHA256.hexdigest("hello"), entries.first["sha256"]
  end

  test "keeps status and covers while the file is unchanged" do
    @manifest.write!
    data = YAML.load_file(@manifest.manifest_path)
    data["files"].first.merge!("status" => "scoped", "covers" => "pp. 1-5")
    File.write(@manifest.manifest_path, data.to_yaml)

    entry = @manifest.build.first
    assert_equal "scoped", entry["status"]
    assert_equal "pp. 1-5", entry["covers"]
  end

  test "a changed file goes back to new with a note" do
    @manifest.write!
    data = YAML.load_file(@manifest.manifest_path)
    data["files"].first["status"] = "done"
    File.write(@manifest.manifest_path, data.to_yaml)
    File.write(File.join(@dir, "scans", "a", "one.docx"), "changed")

    entry = @manifest.build.first
    assert_equal "new", entry["status"]
    assert_match(/Changed since/, entry["notes"])
    assert_equal "done", entry["prior_status"]
  end

  test "needs_scoping unit is not idle even with all files inventoried" do
    @manifest.write!
    data = YAML.load_file(@manifest.manifest_path)
    data["files"].first["status"] = "inventoried"
    File.write(@manifest.manifest_path, data.to_yaml)
    write_queue([ { "id" => "s", "status" => "needs_scoping", "scans" => "scans/a/" } ])
    assert_not @manifest.idle?
  end

  test "empty queue file does not raise" do
    File.write(File.join(@dir, "extraction_queue.yml"), "")
    assert_nothing_raised { @manifest.problems }
  end

  test "idle when nothing is new, pending or proposed" do
    write_queue([ { "id" => "x", "status" => "done", "scans" => "scans/a/" } ])
    assert_not @manifest.idle?
    @manifest.write!
    data = YAML.load_file(@manifest.manifest_path)
    data["files"].first["status"] = "done"
    File.write(@manifest.manifest_path, data.to_yaml)
    assert @manifest.idle?
    write_queue([ { "id" => "p", "status" => "proposed", "scans" => "scans/a/" } ])
    assert_not @manifest.idle?
  end

  test "problems flags unknown queue status and done files with open units" do
    @manifest.write!
    data = YAML.load_file(@manifest.manifest_path)
    data["files"].first["status"] = "done"
    File.write(@manifest.manifest_path, data.to_yaml)
    write_queue([ { "id" => "p", "status" => "pending", "scans" => "scans/a/" },
                  { "id" => "q", "status" => "bogus", "scans" => "scans/a/" } ])
    problems = @manifest.problems
    assert(problems.any? { |p| p.include?("open units p") })
    assert(problems.any? { |p| p.include?("unknown status") })
  end
end
