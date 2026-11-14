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
    [ start_item, answer_item, listen_item, clip_item, recording_item, review_item, lesson_item, tutor_item, conversation_item ].compact
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

    @current_lesson = curriculum_lessons.find do |lesson|
      total = words_in(lesson)
      total.positive? && known_by_lesson.fetch(lesson.id, 0) < total
    end
  end

  private

  attr_reader :user

  def review_item
    count = due_count
    return unless count.positive?

    Item.new(level: :foghlaim, label: I18n.t("daily_path.review_label", count: count),
             title: I18n.t("daily_path.review_title"), path: review_path)
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

  # The comhrá on the current lesson: talking, out loud, in Irish.
  def conversation_item
    return unless current_lesson

    Item.new(level: :labhair, label: I18n.t("daily_path.conversation_label"),
             title: I18n.t("daily_path.conversation_title", number: current_lesson.number),
             path: lesson_conversation_path(current_lesson))
  end

  # The lessons with no words to learn (the introduction, the alphabet) that come
  # before the current lesson, one at a time, until the learner has opened them.
  def start_item
    lesson = curriculum_lessons.take_while { |l| l != current_lesson }
                               .find { |l| words_in(l).zero? && !visited?(l) }
    return unless lesson

    Item.new(level: :foghlaim, label: I18n.t("daily_path.start_label", number: lesson.number),
             title: lesson.title, path: lesson_path(lesson))
  end

  # The current lesson's words as Mayo speakers say them, or, when it has no
  # recordings, the first theme the learner hasn't opened yet (or, once they've
  # opened them all, the one they opened longest ago).
  def listen_item
    count = current_lesson&.vocabulary_items&.with_recording&.count.to_i
    return theme_listen_item unless count.positive?

    Item.new(level: :eist, label: I18n.t("daily_path.listen_label"),
             title: I18n.t("daily_path.listen_title", count: count, number: current_lesson.number),
             path: lesson_path(current_lesson, anchor: "vocabulary"))
  end

  def theme_listen_item
    theme = next_theme
    return unless theme

    Item.new(level: :eist, label: I18n.t("daily_path.listen_label"),
             title: I18n.t("daily_path.theme_listen_title", title: theme.title),
             path: lesson_path(theme, anchor: "vocabulary"))
  end

  # A Mayo speaker using a word from a lesson the learner has finished, in a
  # phrase: one clip a day, the shortest first.
  def clip_item
    return if user.listens.today.exists?

    clip = ListeningClip.next_for(user, lessons: finished_lessons)
    return unless clip

    Item.new(level: :eist, label: I18n.t("daily_path.clip_label"),
             title: I18n.t("daily_path.clip_title", word: clip.vocabulary_item.irish), path: listening_clip_path(clip))
  end

  # Answers from native speakers the learner hasn't heard yet come first.
  def answer_item
    count = user.native_questions.unseen_answers.count
    return unless count.positive?

    Item.new(level: :eist, label: I18n.t("daily_path.answer_label"),
             title: I18n.t("daily_path.answer_title", count: count), path: native_questions_path)
  end

  # About once a week, a whole conversation, to hear how the talk flows: the
  # one behind a clip the learner has heard, where there is one.
  def recording_item
    return if user.listening_times.recent.exists?

    clip = ListeningClip.next_recording_for(user)
    return unless clip

    Item.new(level: :eist, label: I18n.t("daily_path.recording_label"),
             title: I18n.t("daily_path.recording_title", title: clip.abairt_recording_title),
             path: recording_path(clip.abairt_recording_id))
  end

  def finished_lessons
    current_lesson ? curriculum_lessons.take_while { |lesson| lesson != current_lesson } : curriculum_lessons
  end

  def curriculum_lessons
    @curriculum_lessons ||= Lesson.visible_to(user).curriculum.ordered.to_a
  end

  def next_theme
    Lesson.visible_to(user).thematic_vocab.with_recordings.ordered
          .min_by { |lesson| [ visited?(lesson) ? 1 : 0, visits[lesson.id].to_i ] }
  end

  def words_in(lesson) = (@words_by_lesson ||= VocabularyItem.group(:lesson_id).count).fetch(lesson.id, 0)

  def visited?(lesson) = visits.key?(lesson.id)

  def visits = @visits ||= user.lesson_visits.pluck(:lesson_id, :created_at).to_h

  def due_by_lesson
    @due_by_lesson ||= QuizReview.due.where(user: user)
                                 .joins(:quiz_question)
                                 .group("quiz_questions.lesson_id").count
  end

  def known_by_lesson
    @known_by_lesson ||= Lesson.known_word_counts_for(user)
  end
end
