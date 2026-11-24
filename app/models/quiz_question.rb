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

  # Exercise cards have no multiple choice: the learner says or writes their
  # Irish, sees the editors' answer, and rates themselves.
  def self_rated? = source_type == "Exercise"

  # Exercise cards whose exercise no longer has an editor's answer are left out
  # of reviews (the card and its history stay, in case the answer comes back).
  scope :still_answerable, -> {
    where.not(source_type: "Exercise", source_id: Exercise.where.not(id: Exercise.answered.select(:id)).select(:id))
  }

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

    keep_ids += sync_phrases(lesson)
    keep_ids += sync_exercises(lesson)

    # Only vocabulary questions are pruned here. A phrase that becomes
    # ineligible (edited long, English removed) keeps its questions so learners'
    # review history is never wiped by an edit; deleting the phrase removes them.
    where(source_type: "VocabularyItem", lesson_id: lesson.id)
      .where.not(id: keep_ids)
      .destroy_all

    keep_ids.size
  end

  # Short whole phrases join the same bank, so they come back in the daily
  # review. Long sentences are left out: they make poor multiple-choice cards.
  MAX_PHRASE_LENGTH = 80

  def self.sync_phrases(lesson)
    phrases = lesson.phrases.to_a.select do |ph|
      ph.irish.present? && ph.english.present? &&
        ph.irish.length <= MAX_PHRASE_LENGTH && ph.english.length <= MAX_PHRASE_LENGTH
    end
    keep_ids = []

    phrases.each do |phrase|
      DIRECTIONS.each do |direction|
        prompt = direction == "ga_en" ? phrase.irish : phrase.english
        answer = direction == "ga_en" ? phrase.english : phrase.irish

        question = find_or_initialize_by(source: phrase, direction: direction)
        question.lesson = lesson
        question.prompt = prompt
        question.answer = answer
        if question.new_record? || Array(question.distractors).size < DISTRACTOR_COUNT
          attr = direction == "ga_en" ? :english : :irish
          pool = phrases.reject { |o| o.id == phrase.id }.map { |o| o.public_send(attr) }
          pool = pool.compact.uniq.reject { |v| v.casecmp?(answer) }
          if pool.size < DISTRACTOR_COUNT
            extra = Phrase.where.not(id: phrase.id).where.not(lesson_id: lesson.id)
                          .where("length(#{attr}) <= ?", MAX_PHRASE_LENGTH).order(Arel.sql("RANDOM()")).limit(200).pluck(attr)
            pool = (pool + extra.compact_blank).uniq.reject { |v| v.casecmp?(answer) }
          end
          question.distractors = pool.sample(DISTRACTOR_COUNT)
        end
        question.save!
        keep_ids << question.id
      end
    end

    keep_ids
  end

  # Exercises an editor has answered join the bank as one card each, English
  # prompt to the editors' Irish. Only the editors' answer is ever shown; nothing
  # is generated. Like phrases, a card is never pruned here when its answer is
  # removed (see still_answerable); deleting the exercise removes it.
  def self.sync_exercises(lesson)
    lesson.exercises.answered.map do |exercise|
      question = find_or_initialize_by(source: exercise, direction: "en_ga")
      question.lesson = lesson
      question.prompt = exercise.prompt
      question.answer = exercise.answer
      question.distractors = []
      question.save! if question.changed?
      question.id
    end
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
