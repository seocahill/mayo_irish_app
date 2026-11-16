class VocabularyGapsController < ApplicationController
  before_action :require_admin

  def show
    report = VocabularyGaps.new
    @rows = report.rows
    @totals = report.totals
    @repeats = report.repeats
  end
end
