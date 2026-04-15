class GrammarSectionsController < ApplicationController
  before_action :require_admin
  before_action :set_section

  def edit
  end

  def update
    if @section.update(section_params)
      redirect_to edit_lesson_path(@section.grammar_rule.lesson)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_section
    @section = GrammarSection.find(params[:id])
  end

  def section_params
    params.require(:grammar_section).permit(:label, :body)
  end
end
