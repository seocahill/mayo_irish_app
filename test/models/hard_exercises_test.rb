require "test_helper"

class HardExercisesTest < ActiveSupport::TestCase
  setup do
    @lesson = lessons(:one)
    @first = exercises(:one)
    @first.update!(answer: "Dia dhuit")
    @second = @lesson.exercises.create!(number: 2, prompt: "Another", answer: "Freagra", position: 2)
    QuizQuestion.sync_for(@lesson)
    @learner = users(:two)
    @other = users(:newcomer)
  end

  def answer(user, exercise, correct:, at: 1.day.ago)
    question = QuizQuestion.find_by!(source: exercise)
    ReviewLog.create!(user: user, quiz_question: question, prompt: question.prompt, correct: correct,
                      answered_at: at, box_before: 1, box_after: 1)
  end

  test "lists exercises by share of Again, counting each learner who rated Again" do
    answer(@learner, @first, correct: false)
    answer(@other, @first, correct: false)
    answer(@other, @first, correct: true)
    answer(@learner, @second, correct: false)
    3.times { answer(@learner, @second, correct: true) }

    rows = HardExercises.new.rows

    assert_equal [ @first, @second ], rows.map(&:exercise)
    assert_equal [ 3, 2, 2, 67 ], [ rows.first.answers, rows.first.misses, rows.first.learners, rows.first.miss_percent ]
    assert_equal [ 4, 1, 1, 25 ], [ rows.second.answers, rows.second.misses, rows.second.learners, rows.second.miss_percent ]
  end

  test "a tie in share goes to more misses, then to the earlier exercise" do
    [ false, true, true ].each { |correct| answer(@learner, @first, correct: correct) }
    [ false, false, true, true, true, true ].each { |correct| answer(@learner, @second, correct: correct) }
    assert_equal [ @second, @first ], HardExercises.new.rows.map(&:exercise)

    ReviewLog.delete_all
    [ false, true, true ].each { |correct| answer(@learner, @second, correct: correct) }
    [ false, true, true ].each { |correct| answer(@learner, @first, correct: correct) }
    assert_equal [ @first, @second ], HardExercises.new.rows.map(&:exercise)
  end

  test "leaves out too few answers, none Again, old answers, admins and unapproved learners" do
    2.times { answer(@learner, @first, correct: false) }
    3.times { answer(@learner, @second, correct: true) }
    3.times { answer(@learner, @second, correct: false, at: (HardExercises::DAYS + 1).days.ago) }
    3.times { answer(users(:admin), @second, correct: false) }
    3.times { answer(users(:one), @second, correct: false) }

    assert_empty HardExercises.new.rows
  end

  test "word cards never count" do
    word = @lesson.quiz_questions.word_cards.first
    3.times do
      ReviewLog.create!(user: @learner, quiz_question: word, prompt: word.prompt, correct: false,
                        answered_at: 1.day.ago, box_before: 1, box_after: 1)
    end

    assert_empty HardExercises.new.send(:logs)
  end

  test "the limit caps the list, and a deleted exercise drops out" do
    3.times { answer(@learner, @first, correct: false) }
    3.times { answer(@learner, @second, correct: false) }

    assert_equal 1, HardExercises.new(limit: 1).rows.size

    @second.destroy!
    assert_equal [ @first ], HardExercises.new.rows.map(&:exercise)
  end
end
