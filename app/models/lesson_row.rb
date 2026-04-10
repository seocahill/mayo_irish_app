class LessonRow < ApplicationRecord
  belongs_to :lesson

  SECTIONS = %w[grammar texts exercises].freeze

  validates :section, inclusion: { in: SECTIONS }
  validates :position, presence: true

  scope :ordered, -> { order(:position) }
  scope :for_section, ->(s) { where(section: s).ordered }
end
