class TextPassage < ApplicationRecord
  include Searchable

  belongs_to :lesson
  has_many :phrases, as: :source, dependent: :destroy

  has_rich_text :body

  searchable title: ->(t) { t.title.presence || "Text" },
             body: ->(t) { [t.title, t.body&.to_plain_text] },
             lesson_number: ->(t) { t.lesson&.number }
end
