class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show, :edit, :update]
  before_action :require_admin, only: [:new, :create, :edit, :update]

  def index
    @lessons = Lesson.visible_to(current_user).ordered
    @quiz_progress = {}
    if current_user
      totals = VocabularyItem.group(:lesson_id).count
      known = known_words_by_lesson(current_user)
      @quiz_progress = @lessons.each_with_object({}) do |lesson, h|
        h[lesson.id] = LessonProgress.new(
          known: known.fetch(lesson.id, 0),
          total: totals.fetch(lesson.id, 0)
        )
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
    # Draft lessons (e.g. created via the MCP connector) are hidden from learners
    # until an admin publishes them.
    unless @lesson.published? || current_user&.admin?
      redirect_to(root_path, alert: "Lesson not found.") and return
    end

    @quiz_progress = @lesson.progress_for(current_user)

    if current_user
      # Grammar / texts / exercises still come from the chat tutor's mastery
      # markers; vocabulary is now driven by the quiz tracker (source of truth).
      @section_progress = current_user.section_progresses
                                      .where(lesson: @lesson)
                                      .completed
                                      .where.not(section_type: "vocabulary")
                                      .pluck(:section_type)
                                      .to_set
      @section_progress << "vocabulary" if @quiz_progress.complete?
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

  # Words known per lesson (a word counts once all its questions are known),
  # computed in a couple of grouped queries rather than per-lesson.
  def known_words_by_lesson(user)
    questions = QuizQuestion.where(source_type: "VocabularyItem")
                            .group(:lesson_id, :source_id).count
    known = QuizReview.known
                      .joins(:quiz_question)
                      .where(user: user, quiz_questions: { source_type: "VocabularyItem" })
                      .group("quiz_questions.lesson_id", "quiz_questions.source_id").count

    questions.each_with_object(Hash.new(0)) do |((lesson_id, source_id), n), acc|
      acc[lesson_id] += 1 if n.positive? && known[[lesson_id, source_id]].to_i >= n
    end
  end

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
      :published,
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
