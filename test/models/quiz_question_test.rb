require "test_helper"

class QuizQuestionTest < ActiveSupport::TestCase
  setup { @lesson = lessons(:one) }

  test "sync_for builds two questions per vocabulary item" do
    QuizQuestion.sync_for(@lesson)
    assert_equal @lesson.vocabulary_items.count * 2, @lesson.quiz_questions.count
    assert_equal QuizQuestion::DIRECTIONS.sort, @lesson.quiz_questions.distinct.pluck(:direction).sort
  end

  test "sync_for is idempotent" do
    QuizQuestion.sync_for(@lesson)
    assert_no_difference -> { QuizQuestion.count } do
      QuizQuestion.sync_for(@lesson)
    end
  end

  test "each question gets distractors that exclude the answer" do
    QuizQuestion.sync_for(@lesson)
    @lesson.quiz_questions.each do |q|
      assert_equal QuizQuestion::DISTRACTOR_COUNT, q.distractors.size
      assert_not_includes q.distractors, q.answer
      assert_includes q.choices, q.answer
      assert_equal q.distractors.size + 1, q.choices.size
    end
  end

  test "sync_for prunes stray questions no longer backed by lesson vocabulary" do
    QuizQuestion.sync_for(@lesson)
    # A stray row that sync_for should not keep (its source is not a current
    # vocabulary item of the lesson).
    orphan_source = @lesson.vocabulary_items.first
    # A stray row in a slot sync_for will never re-create (unknown direction).
    stray = QuizQuestion.new(
      lesson: @lesson, source: orphan_source, direction: "stray",
      prompt: "x", answer: "y", distractors: %w[a b c]
    )
    stray.save!(validate: false)

    assert_difference -> { QuizQuestion.count }, -1 do
      QuizQuestion.sync_for(@lesson)
    end
    assert_not QuizQuestion.exists?(stray.id)
  end

  test "ga_en question prompts in Irish and answers in English" do
    QuizQuestion.sync_for(@lesson)
    item = @lesson.vocabulary_items.first
    q = QuizQuestion.find_by(source: item, direction: "ga_en")
    assert_equal item.irish, q.prompt
    assert_equal item.english, q.answer
  end

  test "sync_for adds short phrases, skips long ones, and prunes removed ones" do
    QuizQuestion.sync_for(@lesson)
    base = @lesson.quiz_questions.count
    short = @lesson.phrases.create!(irish: "Dia duit", english: "Hello", position: 1)
    @lesson.phrases.create!(irish: "A" * 90, english: "Too long", position: 2)
    @lesson.phrases.create!(irish: "Gan Bhéarla", english: nil, position: 3)

    QuizQuestion.sync_for(@lesson)
    assert_equal base + 2, @lesson.quiz_questions.count
    q = @lesson.quiz_questions.find_by(source: short, direction: "ga_en")
    assert_equal "Hello", q.answer
    assert_not_includes q.distractors, "Hello"

    short.update!(english: nil)
    @lesson.reload
    QuizQuestion.sync_for(@lesson)
    assert_equal base + 2, @lesson.quiz_questions.count, "an edit never prunes learner history"

    short.destroy
    assert_equal base, @lesson.reload.quiz_questions.count
  end

  test "answered exercises get one self-rated card, unanswered ones none" do
    lesson = lessons(:one)
    exercise = exercises(:one)
    QuizQuestion.sync_for(lesson)
    assert_not QuizQuestion.exists?(source: exercise)

    exercise.update!(answer: "Dia dhuit")
    2.times { QuizQuestion.sync_for(lesson) }
    questions = QuizQuestion.where(source: exercise)
    assert_equal 1, questions.count
    question = questions.first
    assert question.self_rated?
    assert_equal "en_ga", question.direction
    assert_equal exercise.prompt, question.prompt
    assert_equal "Dia dhuit", question.answer
    assert_includes QuizQuestion.still_answerable, question
  end

  test "an exercise card follows its answer and leaves reviews when the answer is removed" do
    exercise = exercises(:one)
    exercise.update!(answer: "Dia dhuit")
    QuizQuestion.sync_for(lessons(:one))
    question = QuizQuestion.find_by!(source: exercise)

    exercise.update!(answer: "Dia dhuit, a Mháire")
    assert_equal "Dia dhuit, a Mháire", question.reload.answer

    exercise.update!(answer: "")
    assert_equal "Dia dhuit, a Mháire", question.reload.answer, "the card is kept, not rewritten"
    assert_not_includes QuizQuestion.still_answerable, question
    assert_includes QuizQuestion.still_answerable, lessons(:one).quiz_questions.where(source_type: "VocabularyItem").first

    QuizQuestion.sync_for(lessons(:one))
    assert QuizQuestion.exists?(question.id), "sync never prunes exercise cards"
  end

  test "deleting an exercise removes its card" do
    exercise = exercises(:one)
    exercise.update!(answer: "Dia dhuit")
    QuizQuestion.sync_for(lessons(:one))
    assert_difference -> { QuizQuestion.where(source_type: "Exercise").count }, -1 do
      exercise.destroy!
    end
  end

  test "a word's plural and genitive get their own self-rated cards" do
    dog = vocabulary_items(:dog)
    dog.update_columns(plural: "madraí", genitive: "madra")
    QuizQuestion.sync_for(lessons(:one))

    plural = QuizQuestion.find_by!(source: dog, direction: "plural")
    genitive = QuizQuestion.find_by!(source: dog, direction: "genitive")
    assert_equal [ "madra", "madraí" ], [ plural.prompt, plural.answer ]
    assert_equal "madra", genitive.answer
    assert plural.noun_form?
    assert plural.self_rated?
    assert_equal [ "ga", "ga" ], [ plural.prompt_lang, plural.answer_lang ]
    assert_empty plural.distractors
    assert_not QuizQuestion.exists?(source: vocabulary_items(:house), direction: "plural"), "no form, no card"
  end

  test "noun-form cards are kept out of the multiple-choice and meaning scopes" do
    vocabulary_items(:dog).update_columns(plural: "madraí")
    QuizQuestion.sync_for(lessons(:one))
    plural = QuizQuestion.find_by!(source: vocabulary_items(:dog), direction: "plural")

    assert_not_includes QuizQuestion.word_cards, plural
    assert_not_includes QuizQuestion.meaning_cards, plural
    assert_includes QuizQuestion.noun_form_cards, plural
    assert_includes QuizQuestion.still_answerable, plural
  end

  test "a noun-form card follows an editor's change and goes when the form is removed" do
    dog = vocabulary_items(:dog)
    dog.update!(plural: "madraí")
    plural = QuizQuestion.find_by!(source: dog, direction: "plural")

    dog.update!(plural: "madrannaí")
    assert_equal "madrannaí", plural.reload.answer

    dog.update!(plural: "")
    QuizQuestion.sync_for(lessons(:one))
    assert_not QuizQuestion.exists?(plural.id)
    assert QuizQuestion.exists?(source: dog, direction: "ga_en"), "the meaning cards stay"
  end
end
