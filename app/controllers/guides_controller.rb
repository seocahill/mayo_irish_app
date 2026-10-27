# How the course works, for learners, with a section for editors that only
# admins see. The text is a localised template (show.en.html.erb), as it's
# prose rather than interface strings. Open to everyone, so people can read it
# before they register or while they wait to be let in.
class GuidesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_approval

  def show
  end
end
