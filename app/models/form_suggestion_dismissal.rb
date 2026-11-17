# An editor's "not this one" for a suggested plural or genitive, remembered so
# the same form isn't suggested again for that word.
class FormSuggestionDismissal < ApplicationRecord
  KINDS = %w[plural genitive].freeze

  belongs_to :vocabulary_item

  validates :kind, inclusion: { in: KINDS }
  validates :form, presence: true
end
