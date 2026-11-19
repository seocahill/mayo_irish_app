class LessonsController < ApplicationController
  before_action :set_lesson, only: [:show, :edit, :update]
  before_action :require_admin, only: [:new, :create, :edit, :update]

  def index
    @lessons = Lesson.visible_to(current_user).ordered
    @flagged_count = ChatMessage.flagged.count if current_user&.admin?
    @quiz_progress = {}
    @due_by_lesson = {}
    if current_user
      @due_by_lesson = QuizReview.due.where(user: current_user).joins(:quiz_question)
                                 .where(quiz_questions: { lesson_id: @lessons.map(&:id) })
                                 .group("quiz_questions.lesson_id").count
      totals = VocabularyItem.group(:lesson_id).count
      known = Lesson.known_word_counts_for(current_user)
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
      redirect_to(root_path, alert: t("lessons.flash.not_found")) and return
    end

    @quiz_progress = @lesson.progress_for(current_user)
    # Admins can see the page as a learner would, without the admin controls.
    @preview = current_user&.admin? && params[:preview].present?

    if current_user
      LessonVisit.record(user: current_user, lesson: @lesson)
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
      redirect_to lesson_path(@lesson), notice: t("lessons.flash.saved")
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
      redirect_to root_path, alert: t("lessons.flash.not_authorised")
    end
  end

  # A blank Type in the word list never clears a classification made elsewhere
  # (for example from the gaps report while this form was open).
  def lesson_params
    permitted = permitted_lesson_params
    permitted[:vocabulary_items_attributes]&.each_value { |attrs| attrs.delete(:part_of_speech) if attrs[:part_of_speech].blank? }
    permitted
  end

  def permitted_lesson_params
    params.require(:lesson).permit(
      :title,
      :number,
      :position,
      :published,
      :vocabulary_notes,
      :vocabulary_notes_content,
      :grammar,
      :texts,
      :exercises,
      :tutor_prompt,
      :intro_video_url,
      :intro_video_transcript,
      vocabulary_items_attributes: [
        :id, :irish, :phonetic, :plural, :genitive, :gender, :part_of_speech, :english, :notes, :position, :_destroy
      ]
    )
  end
end
