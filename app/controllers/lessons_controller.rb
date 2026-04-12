class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show, :edit, :update]



  def index
    @lessons = Lesson.ordered
  end

  def new
    @lesson = Lesson.new(position: (Lesson.maximum(:position).to_i + 1))
  end

  def create
    @lesson = Lesson.new(lesson_params)
    @lesson.write_attribute(:vocabulary_notes, "")
    @lesson.write_attribute(:grammar, "")
    @lesson.write_attribute(:texts, "")
    @lesson.write_attribute(:exercises, "")
    if @lesson.save
      redirect_to edit_lesson_path(@lesson)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @lesson.update(lesson_params)
      redirect_to lesson_path(@lesson), notice: "Lesson saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:id])
  end

  def lesson_params
    params.require(:lesson).permit(
      :title,
      :number,
      :position,
      :vocabulary_notes,
      :vocabulary_notes_content,
      :grammar,
      :grammar_data,
      :texts,
      :exercises,
      :tutor_prompt,
      vocabulary_items_attributes: [
        :id, :irish, :phonetic, :plural, :gender, :english, :notes, :position, :_destroy
      ],
      lesson_rows_attributes: [
        :id, :section, :position, :row_type, :col_1, :col_2, :col_3, :_destroy
      ]
    )
  end
end
