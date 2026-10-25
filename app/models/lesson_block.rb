class LessonBlock < ApplicationRecord
  TYPES = %w[text image video pdf audio].freeze

  include Searchable

  belongs_to :lesson
  has_rich_text :body
  has_one_attached :file

  validates :block_type, inclusion: { in: TYPES }
  validate :video_url_must_be_embeddable

  searchable title: ->(b) { b.caption.presence || b.block_type&.titleize },
             body: ->(b) { [b.caption, b.body&.to_plain_text] },
             lesson_number: ->(b) { b.lesson&.number }

  scope :ordered, -> { order(:position) }

  def text? = block_type == "text"
  def image? = block_type == "image"
  def video? = block_type == "video"
  def pdf? = block_type == "pdf"
  def audio? = block_type == "audio"

  def video_embed = VideoEmbed.parse(url)

  private

  def video_url_must_be_embeddable
    return unless video? && url.present? && video_embed.nil?

    errors.add(:url, :unsupported_video)
  end
end
