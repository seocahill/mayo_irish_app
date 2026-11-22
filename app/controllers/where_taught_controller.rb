# Admin-only: where a word is taught, heard and practised across the course.
class WhereTaughtController < ApplicationController
  before_action :require_admin

  def show
    @query = params[:q].to_s.strip
    @locator = WordLocator.new(@query) if @query.present?
  end
end
