class SearchController < ApplicationController
  def index
    @query = params[:q].to_s
    @search = Search.new(@query)
    @results = @search.results
  end
end
