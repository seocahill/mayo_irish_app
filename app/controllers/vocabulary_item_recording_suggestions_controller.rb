# A word's suggested Abairt recordings, searched for and checked the first time
# they're asked for (see RecordingSuggester). Rendered into the word's frame on
# the lesson's review page.
class VocabularyItemRecordingSuggestionsController < ApplicationController
  before_action :require_admin

  def index
    @item = VocabularyItem.find(params[:vocabulary_item_id])
    @suggestions = RecordingSuggester.new(@item).call
  rescue AbairtClient::RateLimited
    @error = t(".rate_limited")
  rescue AbairtClient::Error
    @error = t(".unavailable")
  end
end
