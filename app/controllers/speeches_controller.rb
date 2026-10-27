# Any Irish on a lesson page read aloud by ABAIR's synthetic voice: a bold
# example, or whatever text the learner selects.
class SpeechesController < ApplicationController
  rate_limit to: 60, within: 1.minute, by: -> { current_user.id }, name: "minute"
  rate_limit to: 1000, within: 1.day, by: -> { current_user.id }, name: "day"

  def show
    text = params[:text].to_s.squish
    return head :unprocessable_content if text.blank? || text.length > Pronunciation::MAX_CHARACTERS

    expires_in 1.week
    send_data Pronunciation.new(text).audio, type: "audio/wav", disposition: :inline
  rescue AbairClient::Error
    head :bad_gateway
  end
end
