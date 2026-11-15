# The page the service worker shows when a navigation fails because the
# learner has no connection. Open to everyone and cheap to render, so the
# worker can cache it ahead of time.
class OfflinesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_approval

  # A bare layout: no navigation or CSRF tokens, because the service worker
  # caches this page and shows it to whoever is on the device.
  layout "offline"

  def show
  end
end
