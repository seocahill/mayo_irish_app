require "test_helper"

class ExerciseAttemptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = users(:two)
    @exercise = exercises(:one)
    @lesson = @exercise.lesson
    @exercise.update!(answer: "Tá an ghrian ag scoilteadh na gcloch")
  end

  def frame_headers = { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(@exercise, :attempt) }

  test "the lesson page offers only the exercises editors have answered" do
    unanswered = @lesson.exercises.create!(number: 2, prompt: "An exercise with no answer yet", position: 2)
    sign_in_as(@learner)

    get lesson_path(@lesson)

    assert_select "#exercises" do
      assert_select "li", 1
      assert_select "li", text: /What is the Irish for hello\?/
      assert_select "form[action=?]", exercise_attempt_path(@exercise)
      assert_select "textarea[name=attempt][lang=ga]"
    end
    assert_no_match unanswered.prompt, response.body
    # The answer itself isn't on the page until the learner compares.
    assert_no_match "scoilteadh", response.body
  end

  test "with no answered exercises the lesson has no exercises section" do
    @exercise.update!(answer: nil)
    sign_in_as(@learner)

    get lesson_path(@lesson)

    assert_response :success
    assert_select "#exercises", 0
  end

  test "comparing lines the learner's Irish up against the editors' answer" do
    sign_in_as(@learner)

    post exercise_attempt_path(@exercise), params: { attempt: "Ta an ghrian ag scoilt na gcloch" }, headers: frame_headers

    assert_response :success
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@exercise, :attempt)}" do
      assert_select "[role=status]", text: "6 of the 7 words match the answer."
      assert_select "[data-status=same]", 6
      assert_select "[data-status=different]", text: /scoilteadh.*\(scoilt\)/m
      assert_select "[data-status=same]", text: /Tá.*fada/m
      assert_select "textarea[name=attempt]", text: "Ta an ghrian ag scoilt na gcloch"
    end
  end

  test "every word matching says so" do
    sign_in_as(@learner)

    post exercise_attempt_path(@exercise), params: { attempt: "tá an ghrian ag scoilteadh na gcloch." }, headers: frame_headers

    assert_select "[role=status]", text: "Every word matches the answer."
  end

  test "an empty try shows the form again, not the answer" do
    sign_in_as(@learner)

    post exercise_attempt_path(@exercise), params: { attempt: "  " }, headers: frame_headers

    assert_response :success
    assert_select "[data-testid=exercise-result]", 0
    assert_no_match "scoilteadh", response.body
  end

  test "without Turbo the comparison is a page of its own with a way back" do
    sign_in_as(@learner)

    post exercise_attempt_path(@exercise), params: { attempt: "Tá an ghrian" }

    assert_response :success
    assert_select "a[href=?]", lesson_path(@lesson, anchor: "exercises")
    assert_select "[role=status]", text: "3 of the 7 words match the answer."
  end

  test "an exercise with no answer can't be compared" do
    @exercise.update!(answer: nil)
    sign_in_as(@learner)

    post exercise_attempt_path(@exercise), params: { attempt: "Dia dhuit" }

    assert_response :not_found
  end

  test "a draft lesson's exercises are hidden from learners" do
    draft = Lesson.create!(number: 9300, title: "Draft", position: 9300, published: false)
    hidden = draft.exercises.create!(number: 1, prompt: "Hidden", answer: "Dia dhuit", position: 1)
    sign_in_as(@learner)

    post exercise_attempt_path(hidden), params: { attempt: "Dia dhuit" }

    assert_response :not_found
  end

  test "signed-out visitors are sent to sign in" do
    post exercise_attempt_path(@exercise), params: { attempt: "Dia dhuit" }

    assert_redirected_to new_session_path
  end

  test "admins can compare on a draft lesson" do
    draft = Lesson.create!(number: 9301, title: "Draft", position: 9301, published: false)
    exercise = draft.exercises.create!(number: 1, prompt: "Hidden", answer: "Dia dhuit", position: 1)
    sign_in_as(users(:admin))

    post exercise_attempt_path(exercise), params: { attempt: "Dia dhuit" }

    assert_response :success
  end

  test "with several exercises, each form has its own field, label and prompt" do
    other = @lesson.exercises.create!(number: 2, prompt: "Second prompt", answer: "Dia dhuit", position: 2)
    sign_in_as(@learner)

    get lesson_path(@lesson)

    ids = css_select("#exercises textarea[name=attempt]").map { |t| t["id"] }
    assert_equal 2, ids.uniq.size
    ids.each { |id| assert_select "#exercises label[for=?]", id, 1 }
    [ @exercise, other ].each do |exercise|
      prompt = ActionView::RecordIdentifier.dom_id(exercise, :prompt)
      assert_select "##{prompt}", 1
      assert_select "textarea[aria-describedby~=?]", prompt, 1
    end
  end

  test "a comparison only answers for the exercise it was posted for" do
    @lesson.exercises.create!(number: 2, prompt: "Second prompt", answer: "Slán abhaile", position: 2)
    sign_in_as(@learner)

    post exercise_attempt_path(@exercise), params: { attempt: "Tá" }, headers: frame_headers

    assert_select "turbo-frame", 1
    assert_select "turbo-frame[id=?]", ActionView::RecordIdentifier.dom_id(@exercise, :attempt)
    assert_no_match "Slán", response.body
  end
end
