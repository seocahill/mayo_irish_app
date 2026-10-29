class Lesson < ApplicationRecord
  include Searchable
  include EditHistory

  # Review marks aren't content, and the legacy book columns aren't edited.
  tracked_in_lesson_history lesson_id: ->(l) { l.id },
                            label: ->(l) { l.title },
                            only: %i[title number position published lesson_type intro_video_url
                                     intro_video_transcript tutor_prompt]

  has_rich_text :vocabulary_notes_content

  # A lesson's own free-text fields. Its vocabulary, grammar, texts and
  # exercises are separate Searchable records, so they're not duplicated here.
  searchable title: ->(l) { l.display_title },
             body: ->(l) {
               [
                 l.title,
                 l.read_attribute(:grammar),
                 l.read_attribute(:texts),
                 l.read_attribute(:vocabulary_notes),
                 l.vocabulary_notes_content&.to_plain_text,
                 ActionController::Base.helpers.strip_tags(l.read_attribute(:content_html))
               ]
             },
             lesson_number: ->(l) { l.number }

  has_many :vocabulary_items,  -> { order(:position) }, dependent: :destroy
  has_many :grammar_rules,     -> { order(:position) }, dependent: :destroy
  has_many :grammar_sections,  through: :grammar_rules
  has_many :text_passages,     -> { order(:position) }, dependent: :destroy
  has_many :exercises,         -> { order(:position) }, dependent: :destroy
  has_many :phrases,           -> { order(:position) }, dependent: :destroy
  has_many :lesson_blocks,   -> { order(:position) }, dependent: :destroy
  has_many :lesson_rows, dependent: :destroy
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :section_progresses, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy
  has_many :lesson_visits, dependent: :destroy
  accepts_nested_attributes_for :vocabulary_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  validate :intro_video_must_be_embeddable

  validates :number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :position, presence: true

  TYPES = %w[curriculum thematic_vocab dias_material].freeze

  scope :ordered,      -> { order(:position) }
  scope :curriculum,   -> { where(lesson_type: "curriculum") }
  scope :thematic_vocab, -> { where(lesson_type: "thematic_vocab") }
  scope :dias_material,  -> { where(lesson_type: "dias_material") }
  scope :published,    -> { where(published: true) }
  scope :with_recordings, -> { where(id: VocabularyItem.with_recording.select(:lesson_id)) }

  # Learners only see published lessons; admins see everything (including
  # drafts created through the MCP connector, pending review).
  scope :visible_to, ->(user) { user&.admin? ? all : published }

  # The intro video the teacher recorded for this lesson, if one is set.
  def intro_video = VideoEmbed.parse(intro_video_url)

  # Words without a recording of the course's own, for which Abairt may have
  # one (including ones already taken from Abairt, so they can be changed).
  def words_open_to_abairt_recordings
    vocabulary_items.ordered.with_attached_audio.reject { |item| item.audio.attached? || (item.audio_url.present? && item.audio_credit.blank?) }
  end

  def reviewed? = reviewed_at.present?

  # Drafts nobody has checked yet.
  def needs_review? = !published? && !reviewed?

  def mark_reviewed(by:)
    update!(reviewed_at: Time.current, reviewed_by: by)
  end

  def clear_review
    update!(reviewed_at: nil, reviewed_by: nil)
  end

  def type_label = I18n.t("lessons.types.#{lesson_type}", default: lesson_type.to_s)

  # Words known per lesson for a user (a word counts once all its questions are
  # known), computed in a couple of grouped queries rather than per lesson.
  def self.known_word_counts_for(user)
    questions = QuizQuestion.where(source_type: "VocabularyItem")
                            .group(:lesson_id, :source_id).count
    known = QuizReview.known
                      .joins(:quiz_question)
                      .where(user: user, quiz_questions: { source_type: "VocabularyItem" })
                      .group("quiz_questions.lesson_id", "quiz_questions.source_id").count

    questions.each_with_object(Hash.new(0)) do |((lesson_id, source_id), n), acc|
      acc[lesson_id] += 1 if n.positive? && known[[ lesson_id, source_id ]].to_i >= n
    end
  end

  def to_param
    number.to_s
  end

  def display_title
    "Lesson #{number}: #{title}"
  end

  def next_lesson
    Lesson.where("position > ?", position).order(:position).first
  end

  def previous_lesson
    Lesson.where("position < ?", position).order(position: :desc).first
  end

  # Quiz-based progress for a given user, counted in vocabulary words: a word
  # is "known" once every one of its quiz questions (both directions) is known
  # (Leitner box >= KNOWN_BOX). Total is the word count, so the bar is meaningful
  # even before any questions have been generated.
  def progress_for(user)
    total = vocabulary_items.count
    known = user && total.positive? ? known_word_count(user) : 0
    LessonProgress.new(known: known, total: total)
  end

  private

  def known_word_count(user)
    questions_per_word = quiz_questions.where(source_type: "VocabularyItem").group(:source_id).count
    known_per_word = QuizReview.known
                               .joins(:quiz_question)
                               .where(quiz_questions: { lesson_id: id, source_type: "VocabularyItem" })
                               .where(user: user)
                               .group("quiz_questions.source_id").count

    questions_per_word.count { |source_id, n| n.positive? && known_per_word[source_id].to_i >= n }
  end

  def intro_video_must_be_embeddable
    return if intro_video_url.blank? || intro_video

    errors.add(:intro_video_url, :unsupported_video)
  end
end
