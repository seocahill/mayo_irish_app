# A learner's spoken question to a native speaker. Abairt passes it to a speaker
# on Telegram and files their spoken answer; this keeps track of it for the
# learner, picking up the answer when they next look.
#
#   NativeQuestion.ask!(user: learner, audio: upload, lesson: lesson)
#   question.refresh!  # asks Abairt whether it has been answered yet
class NativeQuestion < ApplicationRecord
  belongs_to :user
  belongs_to :lesson, optional: true
  # Evidence behind ideas a designer saved from this question.
  has_many :proposal_evidence, -> { order(:created_at, :id) }, class_name: "ProposalEvidence", dependent: :nullify

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

  # Saves a designer's own words about this question as an idea in the
  # proposals inbox, with the question as evidence: where it was asked and,
  # if it is answered by then, a link to the speaker's answer (the question
  # stays linked, so a later answer shows on its page). The learner's recording
  # is not attached, so their voice goes no further.
  def save_as_idea!(text, origin:)
    transaction do
      proposal = CourseProposal.capture(text, origin: origin)
      proposal.save!
      proposal.proposal_evidence.create!(native_question: self, source: evidence_source, audio_url: https_answer_audio_url)
      proposal
    end
  end

  def ideas = proposal_evidence.map(&:course_proposal).uniq

  private

  def evidence_source
    I18n.t("native_question.evidence_source", id: abairt_question_id, date: I18n.l(created_at.to_date, format: :long),
           lesson: lesson&.display_title&.truncate(LESSON_TITLE_LENGTH) || I18n.t("native_question.no_lesson"))
  end

  LESSON_TITLE_LENGTH = 200
  AUDIO_URL_LENGTH = 500

  # Only a plain https link that fits the evidence's audio field.
  def https_answer_audio_url
    url = answer_audio_url.to_s
    url if answered? && url.start_with?("https://") && url.length <= AUDIO_URL_LENGTH
  end
end
