class Lesson < ApplicationRecord
  has_rich_text :vocabulary_notes_content

  has_many :vocabulary_items,  -> { order(:position) }, dependent: :destroy
  has_many :grammar_rules,     -> { order(:position) }, dependent: :destroy
  has_many :grammar_sections,  through: :grammar_rules
  has_many :text_passages,     -> { order(:position) }, dependent: :destroy
  has_many :exercises,         -> { order(:position) }, dependent: :destroy
  has_many :phrases,           -> { order(:position) }, dependent: :destroy
  has_many :lesson_blocks,   -> { order(:position) }, dependent: :destroy
  has_many :lesson_rows, dependent: :destroy
  has_many :section_progresses, dependent: :destroy
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

end
