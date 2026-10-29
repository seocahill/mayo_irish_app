# A learner having opened a lesson, at least once. Lessons with no words to
# quiz, such as the introduction, count as done once opened.
class LessonVisit < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  validates :lesson_id, uniqueness: { scope: :user_id }

  def self.record(user:, lesson:) = find_or_create_by!(user: user, lesson: lesson)
end
