class QuizQuestion < ApplicationRecord
  DIRECTIONS = %w[ga_en en_ga].freeze
  # A noun's plural and genitive, as the course holds them, recalled from the
  # word itself once the learner knows what it means (see sync_noun_forms).
  FORM_DIRECTIONS = %w[plural genitive].freeze
  # A noun's gender: masculine or feminine, two choices. Only for words an
  # editor has marked as a noun, since every word has a gender by default.
  GENDER = "gender".freeze
  GENDERS = VocabularyItem::GENDERS.keys.freeze
  DISTRACTOR_COUNT = 3

  belongs_to :lesson
  belongs_to :source, polymorphic: true

  has_many :quiz_reviews, dependent: :destroy

  validates :direction, inclusion: { in: DIRECTIONS + FORM_DIRECTIONS + [ GENDER ] }
  validates :prompt, :answer, presence: true

  # Returns the answer plus distractors, shuffled — ready to render as MC options.
  def choices
    ([ answer ] + Array(distractors)).shuffle
  end

  def prompt_lang = direction == "en_ga" ? "en" : "ga"
  def answer_lang = direction == "ga_en" ? "en" : "ga"

  def noun_form? = FORM_DIRECTIONS.include?(direction)
  def gender? = direction == GENDER
  # A word's or phrase's meaning, as against one of a noun's forms or its gender.
  def meaning? = DIRECTIONS.include?(direction)

  # Exercise and noun-form cards have no multiple choice: the learner says or
  # writes their Irish, sees the course's answer, and rates themselves.
  def self_rated? = source_type == "Exercise" || noun_form?

  scope :exercise_cards, -> { where(source_type: "Exercise") }
  # Multiple-choice cards: a word or phrase in either direction.
  scope :word_cards, -> { where.not(source_type: "Exercise").where(direction: DIRECTIONS) }
  # A word's meaning in either direction: what "words known" counts.
  scope :meaning_cards, -> { where(source_type: "VocabularyItem", direction: DIRECTIONS) }
  scope :noun_form_cards, -> { where(source_type: "VocabularyItem", direction: FORM_DIRECTIONS) }
  scope :gender_cards, -> { where(source_type: "VocabularyItem", direction: GENDER) }
  # Everything learned about a noun after its meaning: forms and gender.
  scope :grammar_of_word_cards, -> { where(source_type: "VocabularyItem", direction: FORM_DIRECTIONS + [ GENDER ]) }

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

    keep_ids += sync_noun_forms(items)
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
  def self.sync_exercises(lesson_or_ids)
    Exercise.answered.where(lesson: lesson_or_ids).map do |exercise|
      question = find_or_initialize_by(source: exercise, direction: "en_ga")
      question.lesson_id = exercise.lesson_id
      question.prompt = exercise.prompt
      question.answer = exercise.answer
      question.distractors = []
      question.save! if question.changed?
      question.id
    end
  end

  # A word with a plural or genitive in the course gets one card for each,
  # the word to its form. Only the course's own form is ever shown; a word
  # without one gets no card, and sync_for prunes the card if it is removed.
  def self.sync_noun_forms(items)
    items.flat_map do |item|
      FORM_DIRECTIONS.filter_map do |direction|
        form = item.public_send(direction)
        next if form.blank? || item.irish.blank?

        question = find_or_initialize_by(source: item, direction: direction)
        question.lesson_id = item.lesson_id
        question.prompt = item.irish
        question.answer = form
        question.distractors = []
        question.save! if question.changed?
        question.id
      end
    end + sync_genders(items)
  end

  # A word an editor marked as a noun gets a two-choice gender card, the word
  # to its gender. The answer is the course's own "m" or "f".
  def self.sync_genders(items)
    items.filter_map do |item|
      next unless item.gender_card? && item.irish.present?

      question = find_or_initialize_by(source: item, direction: GENDER)
      question.lesson_id = item.lesson_id
      question.prompt = item.irish
      question.answer = item.gender
      question.distractors = GENDERS - [ item.gender ]
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
