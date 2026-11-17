# An editor accepts an attested plural or genitive: it fills the field only if
# it is blank, remembers the Abairt entry it came from, and shows in the
# lesson's History like any other edit. The form must be one Abairt really
# offers for this word (checked again here, not just in the page).
class VocabularyItemFormAcceptancesController < ApplicationController
  before_action :require_admin

  def create
    item = VocabularyItem.find(params[:vocabulary_item_id])
    kind = FormSuggestionDismissal::KINDS.find { |k| k == params[:kind].to_s }
    form = params[:form].to_s.squish
    entry_id = params[:entry_id].to_s.match?(/\A\d+\z/) ? params[:entry_id].to_i : nil

    if kind && entry_id && item[kind].blank? && offered?(item, kind, form, entry_id) && item.update(kind => form, "#{kind}_source_entry_id" => entry_id)
      redirect_to vocabulary_gaps_path, notice: t(".saved", form: form, word: item.irish)
    else
      redirect_to vocabulary_gaps_path, alert: t(".not_saved")
    end
  rescue AbairtClient::Error
    redirect_to vocabulary_gaps_path, alert: t(".not_saved")
  end

  private

  def offered?(item, kind, form, entry_id)
    return false if item.form_suggestion_dismissals.exists?(kind: kind, form: form)

    FormSuggester.new(item).call.any? { |c| c.entry_id == entry_id && c.forms.include?(form) }
  end
end
