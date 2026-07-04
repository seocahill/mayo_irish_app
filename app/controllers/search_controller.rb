class SearchController < ApplicationController
  def index
    @query = params[:q].to_s
    @search = Search.new(@query, include_unpublished: current_user&.admin?)
    @results = @search.results
  end
end
