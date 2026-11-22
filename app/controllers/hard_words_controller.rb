# Admin-only: the words learners miss most in review.
class HardWordsController < ApplicationController
  before_action :require_admin

  def show
    @rows = HardWords.new.rows
  end
end
