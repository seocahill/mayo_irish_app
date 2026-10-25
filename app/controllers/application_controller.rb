class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern

  before_action :require_approval
  # PaperTrail's own copy of this runs before sign-in is resolved, so re-declare
  # it to run after, and edits are attributed to the signed-in user.
  before_action :set_paper_trail_whodunnit

  private

  def require_approval
    return unless authenticated?
    return if Current.session&.user&.approved?
    redirect_to pending_approval_path
  end

  def require_admin
    redirect_to root_path unless current_user&.admin?
  end

  def current_user
    Current.session&.user
  end
  helper_method :current_user
end
