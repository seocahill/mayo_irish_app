require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "signed-out visitors are led to signing in and the guide, not registering" do
    get root_path

    assert_response :success
    assert_select "p", text: /Invite only/
    [ new_session_path, guide_path ].each do |path|
      assert_select "main a[href=?]", path
    end
    assert_select "main a[href=?]", new_registration_path, count: 0
  end

  test "every page starts with a skip link to the main content" do
    get root_path

    assert_select "a[href='#main']", text: "Skip to main content"
    assert_select "main#main"
    assert_operator response.body.index('href="#main"'), :<, response.body.index("<header")
  end

  test "learners who have not onboarded are sent to onboarding" do
    sign_in_as(users(:newcomer))
    get root_path
    assert_redirected_to new_onboarding_path
  end

  test "Today carries a hidden install card for the browser to reveal" do
    sign_in_as(users(:two))
    get root_path

    assert_select "section[data-controller=install][hidden]" do
      assert_select "[data-install-target=ios]"
      assert_select "[data-install-target=android]"
      assert_select "button[data-action='install#dismiss']"
    end
  end

  test "Today puts known words in proportion to the words in the course" do
    user = users(:two)
    lesson = lessons(:one)
    QuizQuestion.sync_for(lesson)
    lesson.quiz_questions.each do |q|
      QuizReview.create!(user: user, quiz_question: q, box: 3, fsrs_state: 2, stability: 7.0, due_at: 2.days.from_now)
    end
    sign_in_as(user)
    get root_path

    total = DailyPath.new(user).course_words
    assert_operator DailyPath.new(user).known_words, :>, 0
    assert_select "li", text: /of #{total} in the course/
    assert_response :success
  end

  test "Today shows review answers given this week, and hides the count when there are none" do
    user = users(:two)
    user.review_logs.delete_all
    sign_in_as(user)
    get root_path
    assert_select "p", text: /review answers? this week/, count: 0

    2.times { user.review_logs.create!(prompt: "p", correct: true, box_before: 1, box_after: 2, answered_at: Time.current) }
    user.review_logs.create!(prompt: "miss", correct: false, box_before: 2, box_after: 1, answered_at: Time.current)
    user.review_logs.create!(prompt: "old", correct: true, box_before: 1, box_after: 2, answered_at: 3.weeks.ago)
    get root_path
    assert_select "p", text: /3\s+review answers this week\s+·\s+2 right/
  end

  test "Today shows a time per step and trims the list to the minutes chosen" do
    sign_in_as(users(:two))
    get root_path

    assert_select "a[href=?]", root_path(minutes: 10)
    assert_select "span", text: /about \d+ minutes?/
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one))

    get root_path(minutes: 5)

    assert_select "a[aria-current=true]", text: "5 min"
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one)), count: 0
    assert_select "a[href=?]", lesson_path(lessons(:one))
    assert_select "a[href=?]", root_path, text: "Show everything"
  end

  test "an unknown minutes value is ignored" do
    sign_in_as(users(:two))
    [ "7", "0", "-5", "abc" ].each do |value|
      get root_path(minutes: value)

      assert_response :success
      assert_select "a[aria-current=true]", count: 0
    end
    get root_path(minutes: 7)

    assert_response :success
    assert_select "a[aria-current=true]", count: 0
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one))
  end

  test "shows today's items and the learner's place" do
    sign_in_as(users(:two))
    get root_path

    assert_response :success
    assert_select "h1", "Your day"
    assert_select "a[href=?]", lesson_path(lessons(:one))
    assert_select "a[href=?]", lesson_chat_path(lessons(:one))
    assert_select "a[href=?]", lesson_conversation_path(lessons(:one))
    assert_match "Ballindine", response.body
    assert_match "East Mayo", response.body
    assert_select "a[href=?]", OnboardingsHelper::GAELTACHT_1926_URL
  end

  test "shows where the learner has got to, and what is next" do
    users(:two).listening_times.create!(abairt_recording_id: 1, seconds: 6 * 60)
    sign_in_as(users(:two))
    get root_path

    assert_select "li", text: /Listened for 5 minutes to Mayo speakers.*next: 15 minutes/m
    assert_select "li", text: /Your first words come from a lesson's quiz/
    assert_select "li", text: /No spoken conversation yet/
  end

  test "shows the phrases from Mayo speakers the learner made out, and links to their listening" do
    5.times do |i|
      clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 200 + i, irish: "one madra two",
                                   english: "a phrase", audio_url: "https://clips.test/#{i}", word_count: 3)
      users(:two).listens.create!(listening_clip: clip, understood: true)
    end
    sign_in_as(users(:two))
    get root_path

    assert_select "li", text: /You made out 5 phrases from Mayo speakers.*next: 10/m do
      assert_select "a[href=?]", listens_path
    end
  end

  test "shows the whole conversations the learner followed, and links to their listening" do
    ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 250, irish: "one madra two", english: "a phrase",
                          audio_url: "https://clips.test/250", word_count: 3, abairt_recording_id: 15)
    sign_in_as(users(:two))

    get root_path
    assert_select "li", text: /Conversations you say you followed count here.*next: 1/m

    users(:two).listening_times.create!(abairt_recording_id: 15, seconds: 300, followed: true)
    get root_path

    assert_select "li", text: /You followed a whole conversation from Mayo speakers.*next: 3/m do
      assert_select "a[href=?]", listens_path
    end
  end

  test "shows minutes listened this week" do
    ListeningDay.add(users(:two), 150)
    sign_in_as(users(:two))
    get root_path

    assert_select "p", text: /minutes listened.*3 this week/m
  end

  test "each next step links to where the learner can reach it" do
    sign_in_as(users(:two))
    get root_path

    assert_select "li a[href=?]", review_path, text: /next: 10/
    assert_select "li a[href=?]", listens_path, text: /next: 5 minutes/
    assert_select "li a[href=?]", lessons_path, text: /in one go/
    assert_select "li a[href=?]", lessons_path, text: "next: 1 lesson"
    assert_select "li a[href=?]", listens_path, text: "next: 5", count: 1
  end

  test "shows the review forecast once reviews are scheduled" do
    sign_in_as(users(:two))
    get root_path
    assert_select "p", text: /Tomorrow:/, count: 0

    QuizQuestion.sync_for(lessons(:one))
    QuizReview.create!(user: users(:two), quiz_question: QuizQuestion.first, box: 2, due_at: Time.current.tomorrow.noon)
    get root_path
    assert_select "p", text: /Tomorrow: 1/

    QuizReview.update_all(due_at: 4.days.from_now.noon)
    get root_path
    assert_select "p", text: /Tomorrow: 0 · This week: 1/

    QuizReview.update_all(due_at: 30.days.from_now)
    get root_path
    assert_select "p", text: /Tomorrow:/, count: 0
  end

  test "shows an empty state when there is nothing to do" do
    Lesson.update_all(published: false)
    sign_in_as(users(:two))
    get root_path

    assert_response :success
    assert_match "Nothing is due today", response.body
  end

  test "shows the minutes the learner has spoken" do
    user = users(:two)
    chat = user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
    4.times { chat.chat_messages.create!(role: "user", content: "spoken", spoken_seconds: 30) }
    sign_in_as(user)

    get root_path

    assert_match "minutes spoken", response.body
    assert_match "2 this week", response.body
  end

  test "minutes spoken on Today include recording yourself, with no conversation" do
    user = users(:two)
    4.times { SpeakingDay.add(user, 30) }
    sign_in_as(user)

    get root_path

    assert_match "minutes spoken", response.body
    assert_match "2 this week", response.body
  end

  test "every navigation landmark has its own label" do
    sign_in_as(users(:two))
    get root_path

    labels = css_select("nav").map { |n| n["aria-label"] }
    assert labels.size >= 2
    assert_equal labels.compact.uniq.size, labels.size, "navs need distinct labels: #{labels.inspect}"
  end

  test "shows the exercises the learner knows, and links to the review" do
    exercise = exercises(:one)
    exercise.update!(answer: "Dia dhuit")
    QuizQuestion.sync_for(lessons(:one))
    QuizReview.create!(user: users(:two), quiz_question: QuizQuestion.find_by!(source: exercise),
                       fsrs_state: QuizReview::REVIEW_STATE, stability: 10.0, due_at: 1.week.from_now)
    sign_in_as(users(:two))

    get root_path
    assert_select "li", text: /You know 1 exercise from your review, by your own rating.*next: 3/m do
      assert_select "a[href=?]", review_path
    end
  end
end
