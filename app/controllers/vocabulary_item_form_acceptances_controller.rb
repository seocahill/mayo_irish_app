# An editor accepts an attested plural or genitive: it fills the field only if
# it is blank, remembers the Abairt entry it came from, and shows in the
# lesson's History like any other edit.
class VocabularyItemFormAcceptancesController < ApplicationController
  before_action :require_admin

  def create
    item = VocabularyItem.find(params[:vocabulary_item_id])
    kind = FormSuggestionDismissal::KINDS.find { |k| k == params[:kind].to_s }
    form = params[:form].to_s.squish
    if kind && form.match?(/\A[\p{L}'’]+\z/) && item[kind].blank?
      item.update!(kind => form, "#{kind}_source_entry_id" => params[:entry_id].presence&.to_i)
      redirect_to vocabulary_gaps_path, notice: t(".saved", form: form, word: item.irish)
    else
      redirect_to vocabulary_gaps_path, alert: t(".not_saved")
    end
  end
end
