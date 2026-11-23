# Admin-only: saves a designer's own words about a learner's question as an
# idea in the proposals inbox, with the question attached as evidence.
class LearnerQuestionIdeasController < ApplicationController
  before_action :require_admin

  def create
    question = NativeQuestion.find(params[:learner_question_id])
    question.save_as_idea!(params[:raw_text], origin: current_user.email_address.split("@").first)
    redirect_to learner_questions_path(anchor: helpers.dom_id(question)), notice: t(".saved")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to learner_questions_path(anchor: helpers.dom_id(question)),
                alert: e.record.errors.include?(:raw_text) ? t(".too_long") : t(".blank")
  end
end
