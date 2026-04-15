class TextPassagesController < ApplicationController
  before_action :require_admin
  before_action :set_passage

  def edit
  end

  def update
    if @passage.update(passage_params)
      redirect_to edit_lesson_path(@passage.lesson)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_passage
    @passage = TextPassage.find(params[:id])
  end

  def passage_params
    params.require(:text_passage).permit(:title, :body)
  end
end
