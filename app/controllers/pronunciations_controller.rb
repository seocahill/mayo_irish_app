# The spoken form of a vocabulary item, from ABAIR's synthetic voice. Used when
# the lesson has no recording of the word.
class PronunciationsController < ApplicationController
  rate_limit to: 60, within: 1.minute, by: -> { current_user&.id || request.remote_ip }

  def show
    item = VocabularyItem.joins(:lesson).merge(Lesson.visible_to(current_user)).find(params[:vocabulary_item_id])

    expires_in 1.week
    send_data Pronunciation.new(item.irish).audio, type: "audio/wav", disposition: :inline
  rescue AbairClient::Error
    head :bad_gateway
  end
end
