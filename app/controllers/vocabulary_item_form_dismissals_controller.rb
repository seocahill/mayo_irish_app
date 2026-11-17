# "Not this one": the form isn't suggested again for that word and kind.
class VocabularyItemFormDismissalsController < ApplicationController
  before_action :require_admin

  def create
    item = VocabularyItem.find(params[:vocabulary_item_id])
    kind = params[:kind].to_s
    dismissal = item.form_suggestion_dismissals.find_or_initialize_by(kind: kind, form: params[:form].to_s.squish)
    if dismissal.save
      redirect_to vocabulary_gaps_path, notice: t(".dismissed", form: dismissal.form)
    else
      redirect_to vocabulary_gaps_path, alert: t(".not_saved")
    end
  end
end
