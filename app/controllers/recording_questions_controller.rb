# Editors add and remove the questions learners listen for on a whole
# recording. Only recordings the course offers (behind a listening clip) take
# questions.
class RecordingQuestionsController < ApplicationController
  before_action :require_admin

  def create
    raise ActiveRecord::RecordNotFound unless ListeningClip.recording_offered?(params[:recording_id], to: current_user)

    question = RecordingQuestion.new(question_params.merge(abairt_recording_id: params[:recording_id].to_i, author: current_user))
    if question.save
      redirect_to recording_path(question.abairt_recording_id, anchor: "questions"), notice: t(".saved")
    else
      redirect_to recording_path(params[:recording_id].to_i, anchor: "questions"), alert: question.errors.full_messages.to_sentence
    end
  end

  def destroy
    question = RecordingQuestion.find(params[:id])
    question.destroy!
    redirect_to recording_path(question.abairt_recording_id, anchor: "questions"), notice: t(".removed")
  end

  private

  def question_params
    params.require(:recording_question).permit(:question, :answer)
  end
end
