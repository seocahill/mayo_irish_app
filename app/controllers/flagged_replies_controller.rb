# Comhrá replies learners have flagged, for an editor to look over and dismiss.
class FlaggedRepliesController < ApplicationController
  before_action :require_admin

  def index
    @replies = ChatMessage.flagged.includes(chat_session: %i[lesson user chat_messages]).order(flagged_at: :desc)
  end

  def destroy
    ChatMessage.flagged.find(params[:id]).dismiss_flag!
    redirect_to flagged_replies_path, notice: t(".dismissed")
  end
end
