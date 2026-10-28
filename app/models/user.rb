class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy
  has_many :native_questions, dependent: :destroy
  has_many :listens, dependent: :destroy
  has_many :listening_times, dependent: :destroy
  has_many :section_progresses, dependent: :destroy
  has_many :quiz_reviews, dependent: :destroy
  has_many :review_logs, dependent: :destroy

  # Where the learner is from sets which Mayo dialect they hear first. The
  # regions mirror Abairt's Location dialect regions.
  enum :dialect_region, { erris: "erris", achill: "achill", tourmakeady: "tourmakeady",
                          east_mayo: "east_mayo", other: "other" },
       prefix: :region, validate: { allow_nil: true }

  # Where the learner is starting from; shapes the first-run experience.
  enum :door, { beginner: "beginner", school_irish: "school_irish",
                speaks_irish: "speaks_irish", family: "family" },
       prefix: :door, validate: { allow_nil: true }

  validates :place, :dialect_region, :door, presence: true, on: :onboarding

  normalizes :place, with: ->(p) { p.strip }
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :pending_approval, -> { where(approved: false) }

  def onboarded?
    onboarded_at.present?
  end

  def complete_onboarding(attributes)
    assign_attributes(attributes)
    self.onboarded_at = Time.current
    save(context: :onboarding)
  end

  def approved?
    approved
  end

  def approve!
    update!(approved: true)
  end

  def admin?
    admin
  end
end
