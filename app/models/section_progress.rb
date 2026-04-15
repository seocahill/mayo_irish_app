class SectionProgress < ApplicationRecord
  SECTION_TYPES = %w[vocabulary grammar texts exercises].freeze

  belongs_to :user
  belongs_to :lesson

  validates :section_type, inclusion: { in: SECTION_TYPES }
  validates :section_type, uniqueness: { scope: [ :user_id, :lesson_id ] }

  scope :completed, -> { where.not(completed_at: nil) }

  def completed?
    completed_at.present?
  end

  def self.mark_complete(user:, lesson:, section_type:)
    find_or_initialize_by(user: user, lesson: lesson, section_type: section_type).tap do |sp|
      sp.update!(completed_at: Time.current) unless sp.completed?
    end
  end
end
