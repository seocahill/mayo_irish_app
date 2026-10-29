require "test_helper"

class LessonVisitTest < ActiveSupport::TestCase
  test "records a learner opening a lesson once, however often they open it" do
    2.times { LessonVisit.record(user: users(:two), lesson: lessons(:one)) }

    assert_equal 1, users(:two).lesson_visits.count
  end
end
