# A word's listening clips, searched for and checked the first time they're
# asked for (see ListeningClipFinder). Rendered into the word's frame on the
# lesson's listening clips page.
class VocabularyItemListeningClipsController < ApplicationController
  before_action :require_admin

  def index
    @item = VocabularyItem.find(params[:vocabulary_item_id])
    @clips = ListeningClipFinder.new(@item).call
  rescue AbairtClient::RateLimited
    @error = t(".rate_limited")
  rescue AbairtClient::Error
    @error = t(".unavailable")
  end
end
