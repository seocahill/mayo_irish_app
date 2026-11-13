# How the course is being used, week by week, for admins.
class UsageController < ApplicationController
  before_action :require_admin

  def show
    report = UsageReport.new
    @weeks = report.weeks.reverse
    @stages = report.stages
  end
end
