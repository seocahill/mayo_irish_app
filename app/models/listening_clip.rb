# A short phrase from Abairt in which a Mayo speaker uses one of the course's
# words, for learners to listen to and work out. Only clips ABAIR's recogniser
# confirmed are kept (see ListeningClipFinder); an editor can hide one that
# still isn't suitable.
class ListeningClip < ApplicationRecord
  WORDS = 3..12

  belongs_to :vocabulary_item
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :listens, dependent: :destroy

  enum :status, { listed: "listed", hidden: "hidden" }, validate: true

  validates :abairt_entry_id, uniqueness: true
  validates :irish, :english, :audio_url, presence: true
  validates :word_count, numericality: { only_integer: true, in: WORDS }

  scope :visible_to, ->(user) { user&.admin? ? all : listed }
  scope :shortest_first, -> { order(:word_count, :id) }

  # The shortest clip the learner hasn't listened to yet that uses a word from these lessons.
  def self.next_for(user, lessons:)
    listed.joins(:vocabulary_item).where(vocabulary_items: { lesson_id: lessons })
          .where.not(id: user.listens.select(:listening_clip_id))
          .shortest_first.first
  end

  # Whole recordings are only offered where they're behind a clip the user can see.
  def self.recording_offered?(id, to:) = visible_to(to).exists?(abairt_recording_id: id)

  # A clip whose whole recording the learner hasn't listened to yet: one they
  # heard most recently first, otherwise the first in the course.
  def self.next_recording_for(user)
    clips = listed.where.not(abairt_recording_id: nil)
                  .where.not(abairt_recording_id: user.listening_times.select(:abairt_recording_id))
    clips.joins(:listens).merge(user.listens).order(listens: { created_at: :desc }).first ||
      clips.joins(vocabulary_item: :lesson).order("lessons.position", :word_count).first
  end

  def hide!(by:) = update!(status: "hidden", reviewed_by: by, reviewed_at: Time.current)

  def list!(by:) = update!(status: "listed", reviewed_by: by, reviewed_at: Time.current)
end
