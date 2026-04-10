class Lesson < ApplicationRecord
  has_many :vocabulary_items, -> { order(:position) }, dependent: :destroy
  has_many :lesson_rows, dependent: :destroy
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
