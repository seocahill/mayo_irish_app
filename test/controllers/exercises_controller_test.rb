require "test_helper"

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @learner = users(:two)
    @exercise = exercises(:one)
    @lesson = @exercise.lesson
  end

  test "signed-out visitors are sent to sign in" do
    get edit_exercise_path(@exercise)
    assert_redirected_to new_session_path
  end

  test "learners can't edit an exercise" do
    sign_in_as(@learner)

    get edit_exercise_path(@exercise)
    assert_redirected_to root_path

    patch exercise_path(@exercise), params: { exercise: { answer: "Dia dhuit" } }
    assert_redirected_to root_path
    assert_nil @exercise.reload.answer
  end

  test "the lesson editor lists the exercises and how many have an answer" do
    sign_in_as(@admin)

    get edit_lesson_path(@lesson)

    assert_response :success
    assert_select "#exercises" do
      assert_select "p", text: /0 of 1 have an answer/
      assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@exercise)}", text: /What is the Irish for hello\?/
      assert_select "p", text: "No answer yet"
      assert_select "a[href=?]", edit_exercise_path(@exercise)
    end
  end

  test "an editor writes the answer, and it shows in the editor" do
    sign_in_as(@admin)

    get edit_exercise_path(@exercise)
    assert_response :success
    assert_select "textarea[name='exercise[answer]'][lang=ga]"

    patch exercise_path(@exercise), params: { exercise: { answer: "  Dia dhuit  " } }

    assert_redirected_to edit_lesson_path(@lesson, anchor: "exercises")
    assert_equal "Dia dhuit", @exercise.reload.answer
    follow_redirect!
    assert_select "#exercises p[lang=ga]", text: /Dia dhuit/
    assert_select "#exercises p", text: /1 of 1 have an answer/
  end

  test "clearing the answer leaves it empty, not blank" do
    @exercise.update!(answer: "Dia dhuit")
    sign_in_as(@admin)

    patch exercise_path(@exercise), params: { exercise: { answer: "   " } }

    assert_nil @exercise.reload.answer
  end

  test "an exercise can't lose its prompt" do
    sign_in_as(@admin)

    patch exercise_path(@exercise), params: { exercise: { prompt: "", answer: "Dia dhuit" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_equal "What is the Irish for hello?", @exercise.reload.prompt
  end

  test "the edit is in the lesson's history and can be undone" do
    sign_in_as(@admin)
    patch exercise_path(@exercise), params: { exercise: { answer: "Dia dhuit" } }
    version = PaperTrail::Version.where(item: @exercise).order(:id).last
    assert_equal @lesson.id, version.lesson_id
    assert_equal @admin.id.to_s, version.whodunnit

    get lesson_versions_path(@lesson)
    assert_select "ins", text: "Dia dhuit"
    assert_match "Exercise 1", response.body

    post lesson_version_undo_path(@lesson, version)
    assert_nil @exercise.reload.answer
  end

  test "with Turbo, saving updates the row and the answered count in place" do
    sign_in_as(@admin)

    patch exercise_path(@exercise), params: { exercise: { answer: "Dia dhuit" } }, as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", ActionView::RecordIdentifier.dom_id(@exercise) do
      assert_select "template p[lang=ga]", text: /Dia dhuit/
    end
    assert_select "turbo-stream[action=replace][target=exercises_count] template", text: /1 of 1 have an answer/
  end

  test "an answer of only spaces doesn't count as answered" do
    @exercise.update_column(:answer, "   ")
    assert_not_includes Exercise.answered, @exercise
    @exercise.update_column(:answer, "Dia dhuit")
    assert_includes Exercise.answered, @exercise
  end

  test "the edit form shows the course words in the exercise" do
    @exercise.update!(prompt: "Is the dog in the house?")
    DialectSubstitution.create!(other_form: "deacair", mayo_form: "doiligh")
    sign_in_as(@admin)

    get edit_exercise_path(@exercise)

    assert_response :success
    assert_select "section h4", text: I18n.t("exercises.course_words.heading")
    section = "section[aria-labelledby=#{ActionView::RecordIdentifier.dom_id(@exercise, :course_words)}]"
    assert_select "#{section} li", count: 2
    assert_select "#{section} li span[lang=ga]", text: "madra"
    assert_select "#{section} li", text: /teach\s+· house · this lesson/
    assert_select "#{section} li", text: /doiligh/, count: 0
  end

  test "the edit form lists a Mayo forms pair in an Irish prompt, and says when nothing matched" do
    sign_in_as(@admin)
    @exercise.update!(prompt: "Ní raibh sé ró-dheacair.")
    get edit_exercise_path(@exercise)
    assert_select "section p", text: I18n.t("exercises.course_words.none")

    DialectSubstitution.create!(other_form: "deacair", mayo_form: "doiligh")
    @exercise.update!(prompt: "Tá sé deacair.")
    get edit_exercise_path(@exercise)
    assert_select "section li", text: /#{I18n.t("exercises.course_words.mayo_forms")}/ do
      assert_select "span[lang=ga]", text: "deacair"
      assert_select "strong[lang=ga]", text: "doiligh"
    end
  end
end
