require "test_helper"

class ExerciseWordsTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @later = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
  end

  def words_for(prompt, lesson: @later)
    ExerciseWords.new(Exercise.new(lesson: lesson, number: 1, prompt: prompt))
  end

  test "an English prompt matches course words by their English" do
    words = words_for("Is the dog in the house?")

    assert words.english?
    assert_equal %w[madra teach], words.matches.map { |m| m.item.irish }
    assert_equal [ @lesson ], words.matches.map(&:lesson).uniq
  end

  test "an Irish prompt matches course words by their Irish, accents and mutations aside" do
    words = words_for("Tá an leabhar ar an mbord agus tá uisce sa teach.")
    assert_not words.english?
    assert_equal %w[teach uisce leabhar].sort, words.matches.map { |m| m.item.irish }.sort

    VocabularyItem.create!(lesson: @later, irish: "bean", english: "woman", position: 1)
    assert_equal [ "bean" ], words_for("Tá an bhean ag caint.").matches.map { |m| m.item.irish }
    assert_equal [ "bean" ], words_for("Ní fhaca mé mo bhean.").matches.map { |m| m.item.irish }
  end

  test "the exercise's own lesson comes first, then the course in order" do
    VocabularyItem.create!(lesson: @later, irish: "madra rua", english: "fox", position: 1)

    words = words_for("Saw a fox and a dog.")

    assert_equal [ "madra rua", "madra" ], words.matches.map { |m| m.item.irish }
  end

  test "glosses are split, and short or very common words are left out" do
    VocabularyItem.create!(lesson: @later, irish: "agus", english: "and", position: 1)
    VocabularyItem.create!(lesson: @later, irish: "ar", english: "on", position: 2)
    VocabularyItem.create!(lesson: @later, irish: "bóis", english: "palm (of hand)", position: 3)
    VocabularyItem.create!(lesson: @later, irish: "daor", english: "dear, expensive", position: 4)

    assert_equal %w[daor leabhar], words_for("The book was expensive and the hand was on it").matches.map { |m| m.item.irish }.sort
    assert_empty words_for("Tá sé ar an mbord.").matches
  end

  test "a prompt with no course words finds nothing" do
    words = words_for("Where were you yesterday?")
    assert_empty words.matches
    assert_not words.more?
  end

  test "only the first few are shown" do
    (ExerciseWords::LIMIT + 1).times { |i| VocabularyItem.create!(lesson: @later, irish: "focal#{i}", english: "word#{i}", position: i) }

    words = words_for((0..ExerciseWords::LIMIT).map { |i| "focal#{i}" }.join(" "))

    assert_equal ExerciseWords::LIMIT, words.matches.size
    assert words.more?
  end

  test "Mayo forms pairs found in an Irish prompt" do
    pair = DialectSubstitution.create!(other_form: "deacair", mayo_form: "doiligh")

    assert_equal [ pair ], words_for("Tá sé deacair.").substitutions
    assert_empty words_for("It was deacair, they said.").substitutions
  end

  test "words from later lessons are left out" do
    VocabularyItem.create!(lesson: @later, irish: "cat", english: "cat", position: 1)

    assert_empty words_for("Is the cat in it?", lesson: @lesson).matches
    assert_equal [ "cat" ], words_for("Is the cat in it?").matches.map { |m| m.item.irish }
  end

  test "a word taught in two lessons is shown as in this lesson" do
    VocabularyItem.create!(lesson: @later, irish: "madra", english: "dog", position: 9)

    assert_equal [ @later ], words_for("A dog.").matches.map(&:lesson)
  end

  test "only the prompt's word is taken back to its base form" do
    VocabularyItem.create!(lesson: @later, irish: "hata", english: "hat", position: 1)
    VocabularyItem.create!(lesson: @later, irish: "fuil", english: "blood", position: 2)
    VocabularyItem.create!(lesson: @later, irish: "seomra", english: "room", position: 3)
    VocabularyItem.create!(lesson: @later, irish: "fearr", english: "better", position: 4)

    assert_empty words_for("Céard atá ann? An bhfuil sé ann?").matches
    assert_equal %w[fearr seomra], words_for("B'fhearr liom fanacht san tseomra.").matches.map { |m| m.item.irish }.sort
  end

  test "an Irish headword with a comma or brackets matches each part" do
    VocabularyItem.create!(lesson: @later, irish: "sé, seisean", english: "he", position: 1)
    VocabularyItem.create!(lesson: @later, irish: "cúpla (with sing.)", english: "a couple", position: 2)

    assert_equal [ "sé, seisean", "cúpla (with sing.)" ], words_for("Ní seisean a bhí ann ach cúpla duine.").matches.map { |m| m.item.irish }
  end

  test "am is Irish: an Irish prompt with an t-am in it is matched as Irish" do
    VocabularyItem.create!(lesson: @later, irish: "scoil", english: "school", position: 1)

    words = words_for("Tá an t-am ann don scoil.")
    assert_not words.english?
    assert_equal [ "scoil" ], words.matches.map { |m| m.item.irish }
  end
end
