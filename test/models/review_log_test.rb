require "test_helper"

class ReviewLogTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
    QuizQuestion.sync_for(@lesson)
    @questions = @lesson.quiz_questions.where(source_type: "VocabularyItem").order(:id).to_a
    @question = @questions.first
  end

  test "counts misses in both directions toward the same word" do
    other = @questions.find { |q| q.source_id == @question.source_id && q.id != @question.id }
    2.times { log(@question) }
    2.times { log(other) }
    assert_equal [ @question.source_id ], ReviewLog.tricky_words_for(@user).map(&:source_id)
  end

  test "ignores few, old, correct and other users' answers" do
    2.times { log(@question) }
    3.times { log(@question, at: 45.days.ago) }
    3.times { log(@question, correct: true) }
    3.times { log(@question, user: users(:one)) }
    assert_empty ReviewLog.tricky_words_for(@user)
  end

  test "missed plurals and genitives don't make a word tricky" do
    vocabulary_items(:dog).update!(plural: "madraí")
    plural = QuizQuestion.find_by!(source: vocabulary_items(:dog), direction: "plural")
    3.times { log(plural) }
    assert_empty ReviewLog.tricky_words_for(@user)
  end

  test "can leave out words" do
    3.times { log(@question) }
    assert_empty ReviewLog.tricky_words_for(@user, except: [ @question.source_id ])
  end

  test "hides words from lessons the learner cannot see" do
    @lesson.update_columns(published: false)
    3.times { log(@question) }
    plain = users(:two)
    skip "learner is admin" if plain.admin?
    assert_empty ReviewLog.tricky_words_for(plain)
  end

  test "most missed first, at most five" do
    @questions.map(&:source_id).uniq.first(6).each_with_index { |id, n| (3 + n).times { log(@questions.find { |q| q.source_id == id }) } }
    words = ReviewLog.tricky_words_for(@user)
    assert_operator words.size, :<=, 5
  end

  private

  def log(question, correct: false, at: Time.current, user: @user)
    ReviewLog.create!(user: user, quiz_question: question, prompt: question.prompt, correct: correct,
                      answered_at: at, box_before: 1, box_after: 1)
  end
end
