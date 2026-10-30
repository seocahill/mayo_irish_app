# frozen_string_literal: true

# Mayo entries from Focail Fholaithe (focailfholaithe.fng.ie, counties/8651),
# made freely available by the RIA for non-commercial use. See
# FocailFholaitheImport and data/focail_fholaithe/mayo_lesson_plan.yml.
#
#   rake focail_fholaithe:import
#
# Idempotent. Lessons are created unpublished (numbers 801+, clear of the
# curriculum and the extraction routine) so an admin can review and publish.
namespace :focail_fholaithe do
  desc "Create unpublished vocabulary lessons from the curated Mayo Focail Fholaithe entries"
  task import: :environment do
    lessons = FocailFholaitheImport.from_files.call
    lessons.each { |lesson| puts "  #{lesson.number}. #{lesson.title} — #{lesson.vocabulary_items.count} words" }
    puts "Done. #{lessons.size} draft lessons created/updated."
  rescue FocailFholaitheImport::Conflict => e
    abort e.message
  end
end
