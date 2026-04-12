class LessonBlock < ApplicationRecord
  TYPES = %w[text image video pdf audio].freeze

  belongs_to :lesson
  has_rich_text :body
  has_one_attached :file

  validates :block_type, inclusion: { in: TYPES }


  scope :ordered, -> { order(:position) }

  def text? = block_type == "text"
  def image? = block_type == "image"
  def video? = block_type == "video"
  def pdf? = block_type == "pdf"
  def audio? = block_type == "audio"
end
