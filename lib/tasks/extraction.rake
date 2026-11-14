require_relative "../extraction/manifest"

namespace :extraction do
  desc "Regenerate scans/MANIFEST.yml and report new or changed source files"
  task :manifest do
    manifest = Extraction::Manifest.new(root: Rails.root.to_s)
    entries = manifest.write!
    puts "scans/MANIFEST.yml: #{entries.size} files"
    problems = manifest.problems(entries)
    puts problems.empty? ? "Nothing needs attention." : problems.map { |p| "- #{p}" }
    puts "idle: #{manifest.idle?}"
  end

  desc "Exit non-zero if the manifest is out of date or inconsistent with the queue"
  task :check do
    manifest = Extraction::Manifest.new(root: Rails.root.to_s)
    entries = manifest.build
    stale = !File.exist?(manifest.manifest_path) || manifest.previous.values != entries
    problems = manifest.problems(entries)
    puts "scans/MANIFEST.yml is out of date; run bin/rails extraction:manifest" if stale
    problems.each { |p| puts "- #{p}" }
    exit 1 if stale || problems.any?
  end
end
