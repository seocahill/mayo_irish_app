# Where a learner records a question for a native speaker and hears the
# answers. Unanswered questions are checked with Abairt each time the page is
# opened, which is when the learner would want to know.
class NativeQuestionsController < ApplicationController
  MAX_AUDIO_BYTES = 10.megabytes
  REFRESH_AT_MOST = 10

  before_action :set_lesson

  def index
    @questions = current_user.native_questions.newest_first.includes(:lesson).to_a
    @questions.reject(&:answered?).first(REFRESH_AT_MOST).each { |question| refresh(question) }
    current_user.native_questions.unseen_answers.update_all(answer_seen_at: Time.current)
  end

  def create
    return redirect_to(native_questions_path(lesson: @lesson&.number), alert: t(".no_recording")) unless recording?(params[:audio])

    NativeQuestion.ask!(user: current_user, audio: params[:audio], lesson: @lesson)
    redirect_to native_questions_path(lesson: @lesson&.number), notice: t(".sent")
  rescue AbairtClient::Error
    redirect_to native_questions_path(lesson: @lesson&.number), alert: t(".not_sent")
  end

  private

  # A question can be about a lesson, which is only shown to help the learner find it again.
  def set_lesson
    @lesson = Lesson.visible_to(current_user).find_by(number: params[:lesson]) if params[:lesson].present?
  end

  def recording?(file)
    file.respond_to?(:content_type) && file.content_type.to_s.match?(%r{\A(audio|video)/}) && file.size.between?(1, MAX_AUDIO_BYTES)
  end

  # If Abairt can't be reached, the question just shows as it last stood.
  def refresh(question)
    question.refresh!
  rescue AbairtClient::Error => e
    Rails.logger.warn("[native questions] couldn't refresh #{question.id}: #{e.message}")
  end
end
