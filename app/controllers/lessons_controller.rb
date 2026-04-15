class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show, :edit, :update]
  before_action :require_admin, only: [:new, :create, :edit, :update]

  def index
    @lessons = Lesson.ordered
    if current_user
      completed_by_lesson = current_user.section_progresses.completed.group(:lesson_id).count
      @lesson_progress = @lessons.each_with_object({}) do |lesson, h|
        h[lesson.id] = completed_by_lesson.fetch(lesson.id, 0)
      end
    end
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
    if current_user
      @section_progress = current_user.section_progresses
                                      .where(lesson: @lesson)
                                      .completed
                                      .pluck(:section_type)
                                      .to_set
    else
      @section_progress = Set.new
    end
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

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Not authorised."
    end
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
