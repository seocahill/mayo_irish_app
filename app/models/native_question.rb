# A learner's spoken question to a native speaker. Abairt passes it to a speaker
# on Telegram and files their spoken answer; this keeps track of it for the
# learner, picking up the answer when they next look.
#
#   NativeQuestion.ask!(user: learner, audio: upload, lesson: lesson)
#   question.refresh!  # asks Abairt whether it has been answered yet
class NativeQuestion < ApplicationRecord
  belongs_to :user
  belongs_to :lesson, optional: true

  enum :status, { waiting: "waiting", sent: "sent", answered: "answered" }, validate: true

  validates :abairt_question_id, presence: true, uniqueness: true

  scope :newest_first, -> { order(created_at: :desc) }
  scope :unseen_answers, -> { answered.where(answer_seen_at: nil) }

  # Sends the recording to Abairt, then records the question, so nothing is
  # saved if Abairt doesn't take it.
  def self.ask!(user:, audio:, lesson: nil, abairt: AbairtClient.new)
    sent = abairt.ask(audio, asker_label: asker_label_for(user))
    create!(user: user, lesson: lesson, abairt_question_id: sent.fetch("id"), **attributes_from(sent))
  end

  # How the asker appears to Abairt's admins: the app's API account asks on everyone's behalf.
  def self.asker_label_for(user) = "#{user.email_address.split("@").first}, Mayo Irish course"

  def self.attributes_from(abairt_question)
    {
      status: (abairt_question["status"] == "draft") ? "waiting" : abairt_question["status"],
      audio_url: abairt_question["audio_url"],
      answer_audio_url: abairt_question["answer_audio_url"],
      answered_at: abairt_question["answered_at"]
    }
  end

  def refresh!(abairt: AbairtClient.new)
    update!(self.class.attributes_from(abairt.question(abairt_question_id))) unless answered?
    self
  end

  def new_answer? = answered? && answer_seen_at.nil?
end
