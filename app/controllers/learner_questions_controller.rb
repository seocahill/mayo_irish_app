# Admin-only: the spoken questions learners have sent to native speakers, and
# the answers, so designers can hear what learners get stuck on and fold the
# speakers' answers back into the course. Learners are not named.
class LearnerQuestionsController < ApplicationController
  LIMIT = 100
  REFRESH_AT_MOST = 10

  before_action :require_admin

  def index
    @questions = NativeQuestion.newest_first.includes(:lesson).limit(LIMIT).to_a
    @questions.reject(&:answered?).first(REFRESH_AT_MOST).each { |question| refresh(question) } if AbairtClient.configured?
    @answered = NativeQuestion.answered.count
    @total = NativeQuestion.count
  end

  private

  # Same check as the learner's own page; if Abairt can't be reached the
  # question just shows as it last stood. It never marks an answer as seen.
  def refresh(question)
    question.refresh!
  rescue AbairtClient::Error => e
    Rails.logger.warn("[learner questions] couldn't refresh #{question.id}: #{e.message}")
  end
end
