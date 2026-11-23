# A question an editor writes for a whole Abairt recording, with its answer,
# for learners to listen for (see RecordingsController). Written by people,
# never generated: the app only shows it.
class RecordingQuestion < ApplicationRecord
  MAX_LENGTH = 500

  belongs_to :author, class_name: "User", optional: true

  normalizes :question, :answer, with: ->(v) { v.strip }
  validates :abairt_recording_id, presence: true
  validates :question, :answer, presence: true, length: { maximum: MAX_LENGTH }

  scope :for_recording, ->(id) { where(abairt_recording_id: id).order(:created_at, :id) }
end
