# Plural and genitive forms Mayo speakers have been heard using, looked up in
# Abairt for one noun when an editor asks (see FormSuggester).
class VocabularyItemFormSuggestionsController < ApplicationController
  before_action :require_admin

  def index
    @item = VocabularyItem.find(params[:vocabulary_item_id])
    @kinds = VocabularyGaps.missing_for(@item) & %i[plural genitive]
    @dismissed = @item.form_suggestion_dismissals.pluck(:kind, :form).to_set
    @candidates = FormSuggester.new(@item).call.select { |c| c.forms.any? { |f| @kinds.any? { |k| !@dismissed.include?([ k.to_s, f ]) } } }
  rescue AbairtClient::RateLimited
    @error = t(".rate_limited")
  rescue AbairtClient::Error
    @error = t(".unavailable")
  end
end
