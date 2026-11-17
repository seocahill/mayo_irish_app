# One-tap classification of a single word by an editor (recorded in the
# lesson's History like any other edit, so it can be undone).
class VocabularyItemPartsOfSpeechController < ApplicationController
  before_action :require_admin

  def update
    item = VocabularyItem.find(params[:vocabulary_item_id])
    page = params[:page].to_i.clamp(1, 10_000)
    if params[:part_of_speech].present? && item.update(part_of_speech: params[:part_of_speech])
      redirect_to vocabulary_gaps_path(page: page, anchor: "unclassified"), notice: t(".saved", word: item.irish)
    else
      redirect_to vocabulary_gaps_path(page: page, anchor: "unclassified"), alert: t(".invalid")
    end
  end
end
