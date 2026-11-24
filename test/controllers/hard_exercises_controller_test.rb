require "test_helper"

class HardExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @exercise = exercises(:one)
    @exercise.update!(answer: "Dia dhuit")
    QuizQuestion.sync_for(lessons(:one))
    @question = QuizQuestion.find_by!(source: @exercise)
  end

  def log(user, correct, at: 1.day.ago)
    ReviewLog.create!(user: user, quiz_question: @question, prompt: @question.prompt, correct: correct,
                      answered_at: at, box_before: 1, box_after: 1)
  end

  test "admins see each hard exercise with its answer, figures and links" do
    [ false, false, true ].each { |correct| log(users(:two), correct) }
    sign_in_as(users(:admin))

    get hard_exercises_path

    assert_response :success
    assert_select "#hard-exercise-#{@exercise.id}" do
      assert_select "span[lang=ga]", text: "Dia dhuit"
      assert_match "What is the Irish for hello?", response.body
      assert_select "dd", text: "2 of 3 (67%)"
      assert_select "dd", text: "1"
      assert_select "a[href='#{lesson_path(lessons(:one), anchor: 'exercises')}']"
      assert_select "a[href='#{edit_exercise_path(@exercise)}']"
    end
  end

  test "words, admins' answers, old answers and too few answers are left out" do
    word_question = lessons(:one).quiz_questions.word_cards.first
    3.times do
      ReviewLog.create!(user: users(:two), quiz_question: word_question, prompt: word_question.prompt, correct: false,
                        answered_at: 1.day.ago, box_before: 1, box_after: 1)
    end
    3.times { log(users(:admin), false) }
    3.times { log(users(:two), false, at: (HardExercises::DAYS + 1).days.ago) }
    2.times { log(users(:two), false) }
    sign_in_as(users(:admin))

    get hard_exercises_path

    assert_select "#hard-exercises-none"
    assert_select "#hard-exercises", false
  end

  test "an exercise whose answer was removed still shows, marked as out of the review" do
    3.times { log(users(:two), false) }
    @exercise.update!(answer: "")
    sign_in_as(users(:admin))

    get hard_exercises_path

    assert_select "#hard-exercise-#{@exercise.id}", text: /No answer now/
  end

  test "it is listed in the course tools" do
    sign_in_as(users(:admin))
    get course_tools_path
    assert_select "a[href='#{hard_exercises_path}']"
  end

  test "learners cannot open it" do
    sign_in_as(users(:two))

    get hard_exercises_path

    assert_redirected_to root_path
  end
end
