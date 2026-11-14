# What's new: every note, newest first. Opening the page counts as reading them.
class WhatsNewController < ApplicationController
  def show
    @entries = WhatsNew.current.entries
    @new_ids = current_user.whats_new_unseen.map(&:id)
    current_user.mark_whats_new_seen(WhatsNew.current.latest_id)
  end

  # "Got it" on the card: reads the notes shown, up to the id the card carried
  # (never past the newest note, so a made-up id can't hide future ones).
  def update
    current_user.mark_whats_new_seen([ params[:through].to_i, WhatsNew.current.latest_id ].min)
    redirect_back_or_to root_path
  end
end
