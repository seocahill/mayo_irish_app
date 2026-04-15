class LessonBlocksController < ApplicationController
  before_action :require_admin
  before_action :set_lesson, only: [:create, :reorder]
  before_action :set_block,  only: [:edit, :update, :destroy]

  def create
    block_type = params[:block_type]
    next_pos   = @lesson.lesson_blocks.maximum(:position).to_i + 1
    @block     = @lesson.lesson_blocks.create!(block_type: block_type, position: next_pos)
    redirect_to edit_lesson_block_path(@block)
  end

  def edit
  end

  def update
    if @block.update(block_params)
      redirect_to edit_lesson_path(@block.lesson)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lesson = @block.lesson
    @block.destroy
    redirect_to edit_lesson_path(@lesson)
  end

  def reorder
    params[:order].each_with_index do |id, index|
      @lesson.lesson_blocks.where(id: id).update_all(position: index)
    end
    head :ok
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:lesson_id])
  end

  def set_block
    @block = LessonBlock.find(params[:id])
  end

  def block_params
    params.require(:lesson_block).permit(:caption, :url, :file, :body)
  end
end
