# What a learner could do today, built only from things that exist in the app.
# Each item belongs to a level of exposure (:foghlaim, :cleacht, ...) which sets
# its colour on the home screen.
class DailyPath
  include Rails.application.routes.url_helpers

  Item = Data.define(:level, :label, :title, :path)

  def initialize(user)
    @user = user
  end

  def items
    [ answer_item, review_item, lesson_item, tutor_item ].compact
  end

  def due_count
    due_by_lesson.values.sum
  end

  def known_words
    known_by_lesson.values.sum
  end

  # The first curriculum lesson with vocabulary that isn't fully known yet.
  def current_lesson
    return @current_lesson if defined?(@current_lesson)

    totals = VocabularyItem.group(:lesson_id).count
    @current_lesson = curriculum_lessons.find do |lesson|
      total = totals.fetch(lesson.id, 0)
      total.positive? && known_by_lesson.fetch(lesson.id, 0) < total
    end
  end

  private

  attr_reader :user

  def review_item
    lesson_id, count = due_by_lesson.max_by { |_, n| n }
    return unless count&.positive?

    lesson = Lesson.find_by(id: lesson_id)
    return unless lesson

    Item.new(level: :foghlaim, label: I18n.t("daily_path.review_label", count: count),
             title: I18n.t("daily_path.review_title"), path: lesson_quiz_path(lesson))
  end

  def lesson_item
    return unless current_lesson

    progress = current_lesson.progress_for(user)
    Item.new(level: :foghlaim, label: I18n.t("daily_path.lesson_label", number: current_lesson.number),
             title: I18n.t("daily_path.lesson_title", title: current_lesson.title,
                           known: progress.known, total: progress.total),
             path: lesson_path(current_lesson))
  end

  def tutor_item
    return unless current_lesson

    Item.new(level: :cleacht, label: I18n.t("daily_path.tutor_label"),
             title: I18n.t("daily_path.tutor_title"), path: lesson_chat_path(current_lesson))
  end

  # Answers from native speakers the learner hasn't heard yet come first.
  def answer_item
    count = user.native_questions.unseen_answers.count
    return unless count.positive?

    Item.new(level: :eist, label: I18n.t("daily_path.answer_label"),
             title: I18n.t("daily_path.answer_title", count: count), path: native_questions_path)
  end

  def curriculum_lessons
    @curriculum_lessons ||= Lesson.visible_to(user).curriculum.ordered.to_a
  end

  def due_by_lesson
    @due_by_lesson ||= QuizReview.due.where(user: user)
                                 .joins(:quiz_question)
                                 .group("quiz_questions.lesson_id").count
  end

  def known_by_lesson
    @known_by_lesson ||= Lesson.known_word_counts_for(user)
  end
end
