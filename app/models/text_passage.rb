class TextPassage < ApplicationRecord
  belongs_to :lesson
  has_many :phrases, as: :source, dependent: :destroy

  has_rich_text :body
end
