class GrammarRulesController < ApplicationController
  before_action :set_rule

  def edit
  end

  def update
    if @rule.update(rule_params)
      redirect_to edit_lesson_path(@rule.lesson)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_rule
    @rule = GrammarRule.find(params[:id])
  end

  def rule_params
    params.require(:grammar_rule).permit(:title, :body)
  end
end
