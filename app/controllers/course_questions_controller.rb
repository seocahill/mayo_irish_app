# Ask the course a question in plain English, typed or spoken, from anywhere in
# the app. The answer comes from the lessons themselves (see CourseQuestion) and
# appears in place under the question, without leaving the page.
class CourseQuestionsController < ApplicationController
  class RecordingTooLong < StandardError; end

  rate_limit to: 10, within: 1.minute, by: -> { current_user.id }, name: "minute",
             with: -> { render_failure t("course_questions.create.too_fast") }
  rate_limit to: 100, within: 1.day, by: -> { current_user.id }, name: "day",
             with: -> { render_failure t("course_questions.create.daily_limit") }

  def new
  end

  def create
    @question = params[:question].presence || transcribe(params[:audio])
    return render_failure(t(".nothing_asked")) if @question.blank?

    @answer = CourseQuestion.new(@question, lessons: Lesson.visible_to(current_user)).answer
  rescue CourseQuestion::Error
    render_failure t(".no_answer")
  rescue SpeechTranscriber::Error
    render_failure t(".not_heard")
  rescue RecordingTooLong
    render_failure t(".too_long")
  end

  private

  # What the learner said, as text. Nothing is returned if nothing was recorded.
  def transcribe(audio)
    return if audio.blank?
    raise RecordingTooLong if audio.size > SpeechTranscriber::MAX_AUDIO_BYTES

    SpeechTranscriber.new.transcribe(audio.read, filename: audio.original_filename.presence || "speech.webm")
  end

  def render_failure(message)
    @failure = message
    render :create, status: :unprocessable_content
  end
end
