# Admin-only: the spoken questions learners have sent to native speakers, and
# the answers, so designers can hear what learners get stuck on and fold the
# speakers' answers back into the course. Learners are not named.
class LearnerQuestionsController < ApplicationController
  LIMIT = 100
  # Kept low: every check is a call on the app's one Abairt token, which
  # learners need for sending questions. Their own page checks theirs too.
  REFRESH_AT_MOST = 3

  before_action :require_admin

  def index
    @questions = NativeQuestion.newest_first.includes(:lesson).limit(LIMIT).to_a
    refresh(@questions.reject(&:answered?).first(REFRESH_AT_MOST)) if AbairtClient.configured?
    @answered = NativeQuestion.answered.count
    @total = NativeQuestion.count
  end

  private

  # Same check as the learner's own page, but it never marks an answer as
  # seen. If Abairt can't be reached it stops there, and the questions show as
  # they last stood.
  def refresh(questions)
    questions.each(&:refresh!)
  rescue AbairtClient::Error => e
    Rails.logger.warn("[learner questions] couldn't refresh: #{e.message}")
  end
end
