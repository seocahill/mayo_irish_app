class QuizQuestion < ApplicationRecord
  DIRECTIONS = %w[ga_en en_ga].freeze
  DISTRACTOR_COUNT = 3

  belongs_to :lesson
  belongs_to :source, polymorphic: true

  has_many :quiz_reviews, dependent: :destroy

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :prompt, :answer, presence: true

  # Returns the answer plus distractors, shuffled — ready to render as MC options.
  def choices
    ([ answer ] + Array(distractors)).shuffle
  end

  def prompt_lang = direction == "ga_en" ? "ga" : "en"
  def answer_lang = direction == "ga_en" ? "en" : "ga"

  # Idempotently rebuild the question bank for a lesson from its vocabulary.
  # Cheap and deterministic — no LLM. Creates missing rows, refreshes distractors,
  # and prunes questions whose source vocabulary no longer exists.
  def self.sync_for(lesson)
    items = lesson.vocabulary_items.to_a
    keep_ids = []

    items.each do |item|
      DIRECTIONS.each do |direction|
        prompt = direction == "ga_en" ? item.irish : item.english
        answer = direction == "ga_en" ? item.english : item.irish
        next if prompt.blank? || answer.blank?

        question = find_or_initialize_by(source: item, direction: direction)
        question.lesson = lesson
        question.prompt = prompt
        question.answer = answer
        # Only (re)generate distractors when missing, so repeat syncs are no-ops
        # and stored options stay stable across visits.
        if question.new_record? || Array(question.distractors).size < DISTRACTOR_COUNT
          question.distractors = distractors_for(item, direction, items)
        end
        question.save!
        keep_ids << question.id
      end
    end

    where(source_type: "VocabularyItem", lesson_id: lesson.id)
      .where.not(id: keep_ids)
      .destroy_all

    keep_ids.size
  end

  # Pick up to DISTRACTOR_COUNT wrong answers from sibling vocab (same lesson first,
  # then the wider course if the lesson is too small), excluding the correct answer.
  def self.distractors_for(item, direction, lesson_items)
    attr = direction == "ga_en" ? :english : :irish
    answer = item.public_send(attr)

    pool = lesson_items.reject { |i| i.id == item.id }
                       .map { |i| i.public_send(attr) }

    candidates = pool.compact.uniq.reject { |v| v.casecmp?(answer) }

    if candidates.size < DISTRACTOR_COUNT
      extra = VocabularyItem.where.not(id: item.id)
                            .where.not(lesson_id: item.lesson_id)
                            .limit(200)
                            .pluck(attr)
      candidates = (candidates + extra.compact).uniq
                   .reject { |v| v.casecmp?(answer) }
    end

    candidates.sample(DISTRACTOR_COUNT)
  end
end
