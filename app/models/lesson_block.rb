class LessonBlock < ApplicationRecord
  TYPES = %w[text image video pdf audio embed].freeze
  # Pages other sites may show inside a lesson, such as Abairt's 1926 map.
  EMBED_HOSTS = %w[abairt.com].freeze

  include Searchable
  include EditHistory

  tracked_in_lesson_history lesson_id: ->(b) { b.lesson_id },
                            label: ->(b) { b.caption.presence || b.block_type.to_s.titleize }

  belongs_to :lesson
  has_rich_text :body
  has_one_attached :file

  validates :block_type, inclusion: { in: TYPES }
  validate :video_url_must_be_embeddable
  validate :embed_url_must_be_from_abairt

  searchable title: ->(b) { b.caption.presence || b.block_type&.titleize },
             body: ->(b) { [b.caption, b.body&.to_plain_text] },
             lesson_number: ->(b) { b.lesson&.number }

  scope :ordered, -> { order(:position) }

  def text? = block_type == "text"
  def image? = block_type == "image"
  def video? = block_type == "video"
  def pdf? = block_type == "pdf"
  def audio? = block_type == "audio"
  def embed? = block_type == "embed"

  def video_embed = VideoEmbed.parse(url)

  # Where an embedded page's messages come from, e.g. "https://abairt.com".
  def embed_origin
    uri = embed_uri
    "#{uri.scheme}://#{uri.host}" if uri
  end

  private

  def video_url_must_be_embeddable
    return unless video? && url.present? && video_embed.nil?

    errors.add(:url, :unsupported_video)
  end

  def embed_url_must_be_from_abairt
    return unless embed? && url.present? && embed_uri.nil?

    errors.add(:url, :unsupported_embed)
  end

  def embed_uri
    uri = URI.parse(url.to_s.strip)
    uri if uri.scheme == "https" && EMBED_HOSTS.include?(uri.host)
  rescue URI::InvalidURIError
    nil
  end
end
