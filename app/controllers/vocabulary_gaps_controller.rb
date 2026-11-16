class VocabularyGapsController < ApplicationController
  before_action :require_admin

  def show
    report = VocabularyGaps.new
    @rows = report.rows
    @totals = report.totals
    @repeats = report.repeats
    @silent_lessons = report.silent_lessons
    @thin_themes = report.thin_themes
  end
end
