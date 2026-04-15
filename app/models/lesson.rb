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

  scope :ordered, -> { order(:position) }

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
