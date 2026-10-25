class Lesson < ApplicationRecord
  include Searchable

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
  has_many :section_progresses, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy
  accepts_nested_attributes_for :lesson_rows,
                                allow_destroy: true,
                                reject_if: :all_blank
  accepts_nested_attributes_for :vocabulary_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :number, presence: true, uniqueness: true
  validates :title, presence: true
  validates :position, presence: true

  TYPES = %w[curriculum thematic_vocab dias_material].freeze

  scope :ordered,      -> { order(:position) }
  scope :curriculum,   -> { where(lesson_type: "curriculum") }
  scope :thematic_vocab, -> { where(lesson_type: "thematic_vocab") }
  scope :dias_material,  -> { where(lesson_type: "dias_material") }
  scope :published,    -> { where(published: true) }

  # Learners only see published lessons; admins see everything (including
  # drafts created through the MCP connector, pending review).
  scope :visible_to, ->(user) { user&.admin? ? all : published }

  BADGE_CLASSES = {
    "curriculum"    => "bg-emerald-50 text-emerald-800 border-emerald-200 group-hover:bg-emerald-800 group-hover:text-white group-hover:border-emerald-800",
    "thematic_vocab" => "bg-sky-50 text-sky-800 border-sky-200 group-hover:bg-sky-700 group-hover:text-white group-hover:border-sky-700",
    "dias_material"  => "bg-amber-50 text-amber-800 border-amber-200 group-hover:bg-amber-700 group-hover:text-white group-hover:border-amber-700",
  }.freeze

  TYPE_LABELS = {
    "curriculum"    => "Gaeilge",
    "thematic_vocab" => "Stór Focal",
    "dias_material"  => "DIAS",
  }.freeze

  def badge_classes  = BADGE_CLASSES.fetch(lesson_type, BADGE_CLASSES["curriculum"])
  def type_label     = TYPE_LABELS.fetch(lesson_type, lesson_type)

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

end
