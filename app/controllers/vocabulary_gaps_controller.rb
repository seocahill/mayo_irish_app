class VocabularyGapsController < ApplicationController
  before_action :require_admin

  def show
    report = VocabularyGaps.new
    @rows = report.rows
    @totals = report.totals
    @repeats = report.repeats
    @early_words = report.early_words
    @silent_lessons = report.silent_lessons
    @unpractised_lessons = report.unpractised_lessons
    @ungrammared_lessons = report.ungrammared_lessons
    @unlistened_lessons = report.unlistened_lessons
    @unquestioned_lessons = report.unquestioned_lessons
    @uncredited_lessons = report.uncredited_lessons
    @unreviewed_lessons = report.unreviewed_lessons
    @unread_lessons = report.unread_lessons
    @unsourced_lessons = report.unsourced_lessons
    @empty_lessons = report.empty_lessons
    @thin_themes = report.thin_themes
    @unclassified_count = report.unclassified_count
    @pages = (@unclassified_count.to_f / VocabularyGaps::UNCLASSIFIED_PER_PAGE).ceil
    @page = params[:page].to_i.clamp(1, [ @pages, 1 ].max)
    @unclassified = report.unclassified(page: @page)
  end
end
