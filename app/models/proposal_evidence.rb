# One supporting item behind a course proposal: where it came from (book and
# page, Abairt entry and speaker, or a URL), a verbatim quote if any, and a
# link to audio if any. The quote is kept exactly as given.
class ProposalEvidence < ApplicationRecord
  # "evidence" is uncountable, so the table name and the has_many class_name are explicit.
  self.table_name = "proposal_evidence"

  belongs_to :course_proposal
  # Set when the evidence is a learner's question to a native speaker.
  belongs_to :native_question, optional: true
  validates :source, presence: true, length: { maximum: 500 }
  validates :quote, length: { maximum: 2000 }
  validates :audio_url, length: { maximum: 500 }
  validate :audio_url_is_http

  private

  def audio_url_is_http
    return if audio_url.blank?
    uri = URI.parse(audio_url) rescue nil
    errors.add(:audio_url, "must be an http or https link") unless uri.is_a?(URI::HTTP) && uri.host.present?
  end
end
