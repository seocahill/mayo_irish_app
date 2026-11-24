require "test_helper"

class MilestonesTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @chat = @user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
  end

  test "a new learner has reached nothing and the first steps are next" do
    words, listening, understood, followed, conversation = Milestones.new(@user, known_words: 0).strands

    assert_nil words.reached
    assert_equal 10, words.next_step
    assert_equal 10, words.remaining
    assert_nil listening.reached
    assert_nil understood.reached
    assert_equal 5, understood.next_step
    assert_nil followed.reached
    assert_equal 1, followed.next_step
    assert_nil conversation.reached
    assert_not words.started?
  end

  test "words known show the last step reached and the next" do
    words = Milestones.new(@user, known_words: 60).strands.first

    assert_equal 50, words.reached
    assert_equal 100, words.next_step
    assert_equal 40, words.remaining
  end

  test "the top step leaves nothing next" do
    words = Milestones.new(@user, known_words: 1500).strands.first

    assert_equal 1000, words.reached
    assert words.finished?
  end

  test "listening counts minutes across recordings" do
    ListeningTime.create!(user: @user, abairt_recording_id: 1, seconds: 20 * 60)

    listening = Milestones.new(@user, known_words: 0).strands.second

    assert_equal 15, listening.reached
    assert_equal 30, listening.next_step
  end

  test "conversation uses the longest single conversation, not the total" do
    other = @user.chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
    8.times { @chat.chat_messages.create!(role: "user", content: "a", spoken_seconds: 30) }
    4.times { other.chat_messages.create!(role: "user", content: "b", spoken_seconds: 30) }
    @chat.chat_messages.create!(role: "user", content: "typed")

    conversation = Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :conversation }

    assert_equal 3, conversation.reached
    assert_equal 5, conversation.next_step
  end

  test "recording yourself does not count towards the conversation milestone" do
    20.times { SpeakingDay.add(@user, 30, on: Date.new(2026, 11, 1) + it) }

    assert_equal 0, Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :conversation }.value
  end

  test "other learners' conversations are not counted" do
    chat = users(:admin).chat_sessions.create!(lesson: lessons(:one), kind: :conversation)
    10.times { chat.chat_messages.create!(role: "user", content: "x", spoken_seconds: 30) }

    assert_nil Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :conversation }.reached
  end

  test "a value just under a step has not reached it" do
    ListeningTime.create!(user: @user, abairt_recording_id: 1, seconds: 4 * 60)

    assert_nil Milestones.new(@user, known_words: 9).strands.first.reached
    assert_nil Milestones.new(@user).strands.second.reached
  end

  test "grammar counts lessons whose grammar the learner has used in conversation" do
    SectionProgress.mark_complete(user: @user, lesson: lessons(:one), section_type: "grammar")
    SectionProgress.mark_complete(user: @user, lesson: lessons(:one), section_type: "texts")
    SectionProgress.mark_complete(user: users(:admin), lesson: lessons(:one), section_type: "grammar")

    grammar = Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :grammar }

    assert_equal :grammar, grammar.key
    assert_equal 1, grammar.value
    assert_equal 1, grammar.reached
    assert_equal 3, grammar.next_step
  end

  test "grammar starts at nothing and ignores unfinished sections" do
    SectionProgress.create!(user: @user, lesson: lessons(:one), section_type: "grammar")

    grammar = Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :grammar }

    assert_equal 0, grammar.value
    assert_nil grammar.reached
    assert_equal 1, grammar.next_step
  end

  test "phrases made out count the clips the learner said they made out, once each" do
    clips = 7.times.map do |i|
      ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 100 + i, irish: "one madra two",
                            english: "a phrase", audio_url: "https://clips.test/#{i}", word_count: 3)
    end
    clips.first(6).each { |clip| @user.listens.create!(listening_clip: clip, understood: true) }
    @user.listens.create!(listening_clip: clips.last, understood: false)
    users(:one).listens.create!(listening_clip: clips.last, understood: true)

    understood = Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :understood }

    assert_equal 6, understood.value
    assert_equal 5, understood.reached
    assert_equal 10, understood.next_step
  end

  test "a clip an editor hides stops counting as made out, as on the listening page" do
    clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 300, irish: "one madra two",
                                 english: "a phrase", audio_url: "https://clips.test/300", word_count: 3)
    @user.listens.create!(listening_clip: clip, understood: true)
    understood = -> { Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :understood }.value }

    assert_equal 1, understood.call
    clip.update!(status: "hidden")
    assert_equal 0, understood.call
  end

  test "conversations followed count the whole recordings the learner said they followed, still offered" do
    [ 15, 16, 17, 18 ].each.with_index do |recording, i|
      ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 400 + i, irish: "one madra two",
                            english: "a phrase", audio_url: "https://clips.test/4#{i}", word_count: 3, abairt_recording_id: recording)
    end
    @user.listening_times.create!(abairt_recording_id: 15, seconds: 60, followed: true)
    @user.listening_times.create!(abairt_recording_id: 16, seconds: 60, followed: true)
    @user.listening_times.create!(abairt_recording_id: 17, seconds: 60, followed: true)
    @user.listening_times.create!(abairt_recording_id: 18, seconds: 60, followed: false)
    @user.listening_times.create!(abairt_recording_id: 99, seconds: 60, followed: true) # no longer offered
    @user.listening_times.create!(abairt_recording_id: 19, seconds: 60) # listened, never answered
    users(:one).listening_times.create!(abairt_recording_id: 18, seconds: 60, followed: true)
    followed = -> { Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :followed } }

    assert_equal 3, followed.call.value
    assert_equal 3, followed.call.reached
    assert_equal 5, followed.call.next_step

    ListeningClip.find_by(abairt_recording_id: 17).update!(status: "hidden")
    assert_equal 2, followed.call.value
    assert_equal 1, followed.call.reached
  end

  def exercise_strand = Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :exercises }

  def known_review(question, stability: QuizReview::KNOWN_STABILITY)
    QuizReview.create!(user: @user, quiz_question: question, fsrs_state: QuizReview::REVIEW_STATE, stability: stability, due_at: 1.day.from_now)
  end

  test "exercises known count once the course has an answered exercise" do
    assert_not_includes Milestones.new(@user, known_words: 0).strands.map(&:key), :exercises

    exercise = exercises(:one)
    exercise.update!(answer: "Dia dhuit")
    QuizQuestion.sync_for(lessons(:one))
    assert_equal 0, exercise_strand.value
    assert_equal 1, exercise_strand.next_step

    review = known_review(QuizQuestion.find_by!(source: exercise), stability: 3.0)
    assert_equal 0, exercise_strand.value, "not yet stable"

    review.update!(stability: QuizReview::KNOWN_STABILITY)
    assert_equal 1, exercise_strand.value
    assert_equal 1, exercise_strand.reached
    assert_equal 3, exercise_strand.next_step

    exercise.update!(answer: "")
    assert_not_includes Milestones.new(@user, known_words: 0).strands.map(&:key), :exercises
  end

  test "known words, exercises whose answer was removed and exercises in hidden lessons don't count" do
    lessons(:one).exercises.create!(number: 2, prompt: "Another", answer: "Freagra", position: 2)
    exercise = exercises(:one)
    exercise.update!(answer: "Dia dhuit")
    QuizQuestion.sync_for(lessons(:one))
    known_review(lessons(:one).quiz_questions.word_cards.first)
    known_review(QuizQuestion.find_by!(source: exercise))
    assert_equal 1, exercise_strand.value

    exercise.update!(answer: "")
    assert_equal 0, exercise_strand.value, "the other answered exercise keeps the line"

    exercise.update!(answer: "Dia dhuit")
    hidden = Lesson.create!(number: 97, title: "Hidden", lesson_type: "curriculum", position: 97, published: false)
    hidden_exercise = hidden.exercises.create!(number: 1, prompt: "Hidden", answer: "Folaithe", position: 1)
    QuizQuestion.sync_for(hidden)
    known_review(QuizQuestion.find_by!(source: hidden_exercise))
    assert_equal 1, exercise_strand.value
  end

  def noun_form_strand = Milestones.new(@user, known_words: 0).strands.find { |s| s.key == :noun_forms }

  test "plurals and genitives known count once the course has a noun form" do
    VocabularyItem.update_all(plural: nil, genitive: nil)
    assert_not_includes Milestones.new(@user, known_words: 0).strands.map(&:key), :noun_forms

    dog = vocabulary_items(:dog)
    dog.update!(plural: "dog-pl", genitive: "dog-gen")
    assert_equal 0, noun_form_strand.value
    assert_equal 1, noun_form_strand.next_step

    plural = QuizQuestion.find_by!(source: dog, direction: "plural")
    review = known_review(plural, stability: 3.0)
    assert_equal 0, noun_form_strand.value, "not yet stable"

    review.update!(stability: QuizReview::KNOWN_STABILITY)
    assert_equal 1, noun_form_strand.value
    assert_equal 1, noun_form_strand.reached
    assert_equal 5, noun_form_strand.next_step
  end

  test "known meanings and forms in hidden lessons don't count as noun forms" do
    dog = vocabulary_items(:dog)
    dog.update!(plural: "dog-pl")
    QuizQuestion.sync_for(dog.lesson)
    QuizQuestion.meaning_cards.where(source: dog).each { |q| known_review(q) }
    assert_equal 0, noun_form_strand.value

    known_review(QuizQuestion.find_by!(source: dog, direction: "plural"))
    assert_equal 1, noun_form_strand.value
    other = Lesson.create!(number: 97, title: "Other", lesson_type: "curriculum", position: 50, published: true)
    other.vocabulary_items.create!(irish: "cat", english: "cat", plural: "cat-pl")
    dog.lesson.update_columns(published: false)
    assert_equal 0, noun_form_strand.value
  end
end
