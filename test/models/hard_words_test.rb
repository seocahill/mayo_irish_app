require "test_helper"

class HardWordsTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    QuizQuestion.sync_for(@lesson)
    @learner = users(:two)
    @other = users(:newcomer)
  end

  def answer(user, item, correct:, at: 1.day.ago, direction: "ga_en")
    question = @lesson.quiz_questions.find_by!(source: item, direction: direction)
    ReviewLog.create!(user: user, quiz_question: question, prompt: question.prompt, correct: correct,
                      answered_at: at, box_before: 1, box_after: 1)
  end

  test "lists words by share of wrong answers, counting both directions and each learner who missed" do
    dog = vocabulary_items(:dog)
    house = vocabulary_items(:house)
    answer(@learner, dog, correct: false)
    answer(@learner, dog, correct: false, direction: "en_ga")
    answer(@other, dog, correct: false)
    answer(@other, dog, correct: true)
    answer(@learner, house, correct: false)
    3.times { answer(@learner, house, correct: true) }

    rows = HardWords.new.rows

    assert_equal [ dog, house ], rows.map(&:item)
    assert_equal [ 4, 3, 2, 75 ], [ rows.first.answers, rows.first.misses, rows.first.learners, rows.first.miss_percent ]
    assert_equal [ 4, 1, 1, 25 ], [ rows.second.answers, rows.second.misses, rows.second.learners, rows.second.miss_percent ]
  end

  test "leaves out words with too few answers, none wrong, old answers and admins" do
    dog = vocabulary_items(:dog)
    house = vocabulary_items(:house)
    water = vocabulary_items(:water)
    2.times { answer(@learner, dog, correct: false) }
    3.times { answer(@learner, house, correct: true) }
    3.times { answer(@learner, water, correct: false, at: (HardWords::DAYS + 1).days.ago) }
    3.times { answer(users(:admin), water, correct: false) }

    assert_empty HardWords.new.rows
  end

  test "unapproved learners do not count" do
    3.times { answer(users(:one), vocabulary_items(:dog), correct: false) }

    assert_empty HardWords.new.rows
  end

  test "a word with exactly the minimum answers is shown; ties go to more misses" do
    dog = vocabulary_items(:dog)
    house = vocabulary_items(:house)
    [ false, true, true ].each { |correct| answer(@learner, dog, correct: correct) }
    [ false, false, true, true, true, true ].each { |correct| answer(@learner, house, correct: correct) }

    rows = HardWords.new.rows

    assert_equal [ house, dog ], rows.map(&:item)
    assert_equal 3, rows.second.answers
  end

  test "a word deleted after it was answered gives no row" do
    dog = vocabulary_items(:dog)
    3.times { answer(@learner, dog, correct: false) }
    dog.destroy!

    assert_empty HardWords.new.rows
  end

  test "shows at most the limit, hardest first" do
    dog = vocabulary_items(:dog)
    house = vocabulary_items(:house)
    3.times { answer(@learner, dog, correct: false) }
    [ false, true, true ].each { |correct| answer(@learner, house, correct: correct) }

    assert_equal [ dog ], HardWords.new(limit: 1).rows.map(&:item)
  end

  test "missed plurals and genitives are left out" do
    vocabulary_items(:dog).update!(plural: "dog-pl")
    question = QuizQuestion.find_by!(source: vocabulary_items(:dog), direction: "plural")
    3.times do
      ReviewLog.create!(user: @learner, quiz_question: question, prompt: question.prompt, correct: false,
                        answered_at: 1.day.ago, box_before: 1, box_after: 1)
    end
    assert_empty HardWords.new.rows
  end
end
