require "test_helper"

class DailyPathTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
    QuizQuestion.sync_for(@lesson)
  end

  test "suggests the first unfinished lesson, a tutor chat and a conversation for it" do
    items = DailyPath.new(@user).items

    assert_equal [ :foghlaim, :cleacht, :labhair ], items.map(&:level)
    assert_equal "Learn · Lesson 1", items.first.label
    assert_equal [ "/lessons/1", "/lessons/1/chat", "/lessons/1/conversation" ], items.map(&:path)
  end

  test "offers the lesson's words from Mayo speakers when there are recordings" do
    vocabulary_items(:dog).update!(audio_url: "https://abairt.com/madra.mp3")

    listen = DailyPath.new(@user).items.first

    assert_equal :eist, listen.level
    assert_equal "Hear a word from Lesson 1 said by a Mayo speaker", listen.title
    assert_equal "/lessons/1#vocabulary", listen.path
  end

  test "adds a review item with the due count and quiz link" do
    @lesson.quiz_questions.first(3).each do |question|
      QuizReview.create!(user: @user, quiz_question: question, box: 2, due_at: 1.hour.ago)
    end

    review = DailyPath.new(@user).items.first

    assert_equal :foghlaim, review.level
    assert_equal "Review · 3 due", review.label
    assert_equal "/lessons/1/quiz", review.path
  end

  test "ignores reviews that are not due yet or belong to someone else" do
    question = @lesson.quiz_questions.first
    QuizReview.create!(user: @user, quiz_question: question, box: 3, due_at: 2.days.from_now)
    QuizReview.create!(user: users(:admin), quiz_question: question, box: 2, due_at: 1.hour.ago)

    assert_equal 0, DailyPath.new(@user).due_count
  end

  test "counts known words and moves on when a lesson is complete" do
    @lesson.quiz_questions.each do |question|
      QuizReview.create!(user: @user, quiz_question: question, box: 3, due_at: 2.days.from_now)
    end
    path = DailyPath.new(@user)

    assert_equal @lesson.vocabulary_items.count, path.known_words
    assert_nil path.current_lesson
    assert_empty path.items
  end

  test "starts a new learner on the lessons with no words to learn, one at a time, until they've opened them" do
    @lesson.update!(position: 2)
    intro = Lesson.create!(number: 0, title: "Background", position: 0)
    alphabet = Lesson.create!(number: 90, title: "The Alphabet", position: 1)

    assert_equal [ "Start here · Lesson 0", "/lessons/0" ], DailyPath.new(@user).items.first.to_h.values_at(:label, :path)

    LessonVisit.record(user: @user, lesson: intro)
    assert_equal "/lessons/90", DailyPath.new(@user).items.first.path

    LessonVisit.record(user: @user, lesson: alphabet)
    assert_equal "/lessons/1", DailyPath.new(@user).items.first.path
  end

  test "does not suggest draft lessons to learners" do
    @lesson.update!(published: false)

    assert_nil DailyPath.new(@user).current_lesson
  end
end

class DailyPathListeningTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @first = lessons(:one)
    @second = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    @second.vocabulary_items.create!(irish: "bord", english: "table", position: 1)
    [ @first, @second ].each { |lesson| QuizQuestion.sync_for(lesson) }
    @clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 1, irish: "one madra two",
                                  english: "a phrase", audio_url: "https://clips.test/1", word_count: 3)
  end

  def finish(lesson)
    lesson.quiz_questions.each { |question| QuizReview.create!(user: @user, quiz_question: question, box: 3, due_at: 2.days.from_now) }
  end

  def clip_item = DailyPath.new(@user).items.find { |item| item.label == "Listen · real speech" }

  test "offers a phrase using a word from a lesson the learner has finished" do
    finish(@first)

    assert_equal "Hear a Mayo speaker use “madra” in a phrase", clip_item.title
    assert_equal "/listening_clips/#{@clip.id}", clip_item.path
  end

  test "offers no phrases from the lesson the learner is still on" do
    assert_nil clip_item
  end

  test "offers one phrase a day" do
    finish(@first)
    ListeningClip.create!(vocabulary_item: vocabulary_items(:house), abairt_entry_id: 2, irish: "one teach two",
                          english: "another phrase", audio_url: "https://clips.test/2", word_count: 3)
    @user.listens.create!(listening_clip: @clip, understood: false)

    assert_nil clip_item
  end

  test "offers a theme's words from Mayo speakers when the current lesson has no recordings" do
    theme = Lesson.create!(number: 50, title: "Animals", position: 50, lesson_type: "thematic_vocab")
    theme.vocabulary_items.create!(irish: "cat", english: "cat", position: 1, audio_url: "https://abairt.com/cat.mp3")

    listen = DailyPath.new(@user).items.find { |item| item.label == "Listen · Mayo speakers" }

    assert_equal "Animals: hear the words said by Mayo speakers", listen.title
    assert_equal "/lessons/50#vocabulary", listen.path
  end

  test "offers the first theme the learner hasn't opened, then the one opened longest ago" do
    animals, birds = [ "Animals", "Birds" ].each_with_index.map do |title, i|
      Lesson.create!(number: 50 + i, title: title, position: 50 + i, lesson_type: "thematic_vocab").tap do |theme|
        theme.vocabulary_items.create!(irish: title, english: title, position: 1, audio_url: "https://abairt.com/#{i}.mp3")
      end
    end
    theme_listen = -> { DailyPath.new(@user).items.find { |item| item.label == "Listen · Mayo speakers" }.path }

    assert_equal "/lessons/50#vocabulary", theme_listen.call
    LessonVisit.record(user: @user, lesson: animals)
    assert_equal "/lessons/51#vocabulary", theme_listen.call
    travel 1.minute
    LessonVisit.record(user: @user, lesson: birds)
    assert_equal "/lessons/50#vocabulary", theme_listen.call
  end

  def recording_item = DailyPath.new(@user).items.find { |item| item.label == "Listen · conversation" }

  test "offers the whole conversation behind a clip, about once a week" do
    @clip.update!(abairt_recording_id: 15, abairt_recording_title: "A Story")

    assert_equal "A few minutes of Mayo speakers talking: A Story", recording_item.title
    assert_equal "/recordings/15", recording_item.path

    @user.listening_times.create!(abairt_recording_id: 15, seconds: 60)
    assert_nil recording_item

    travel 8.days
    assert_nil recording_item, "already heard, and there's no other"
  end

  test "offers the conversation behind the clip the learner heard most recently" do
    @clip.update!(abairt_recording_id: 15, abairt_recording_title: "A Story")
    heard = ListeningClip.create!(vocabulary_item: vocabulary_items(:house), abairt_entry_id: 2, irish: "one teach two", english: "another",
                                  audio_url: "https://clips.test/2", word_count: 5, abairt_recording_id: 16, abairt_recording_title: "Another Story")
    @user.listens.create!(listening_clip: heard, understood: true)

    assert_equal "/recordings/16", recording_item.path
  end
end
