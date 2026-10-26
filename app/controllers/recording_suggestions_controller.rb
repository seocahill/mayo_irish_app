# An editor approves or rejects one suggested recording.
class RecordingSuggestionsController < ApplicationController
  before_action :require_admin

  def update
    suggestion = RecordingSuggestion.find(params[:id])
    case params[:status]
    when "approved" then suggestion.approve!(by: current_user)
    when "rejected" then suggestion.reject!(by: current_user)
    else return head :unprocessable_content
    end

    redirect_to vocabulary_item_recording_suggestions_path(suggestion.vocabulary_item)
  end
end
