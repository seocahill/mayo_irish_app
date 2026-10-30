require "test_helper"
require "rake"

class FocailFholaitheTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("focail_fholaithe:import")
    Rake::Task["focail_fholaithe:import"].reenable
  end

  test "imports unpublished vocabulary lessons without duplicating on a second run" do
    capture_io { Rake::Task["focail_fholaithe:import"].invoke }
    lessons = Lesson.where("title LIKE 'Focail Fholaithe:%'")
    words = VocabularyItem.where(lesson: lessons).count

    assert_equal 10, lessons.count
    assert lessons.none?(&:published)
    assert_equal ["thematic_vocab"], lessons.pluck(:lesson_type).uniq
    assert words.positive?

    Rake::Task["focail_fholaithe:import"].reenable
    capture_io { Rake::Task["focail_fholaithe:import"].invoke }
    assert_equal words, VocabularyItem.where(lesson: lessons).count
    assert_equal 10, lessons.count
  end
end
