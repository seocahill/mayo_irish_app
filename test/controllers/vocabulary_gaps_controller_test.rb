require "test_helper"

class VocabularyGapsControllerTest < ActionDispatch::IntegrationTest
  test "admins see words that lack a genitive, plural or recording" do
    item = vocabulary_items(:dog)
    item.update!(part_of_speech: "noun", genitive: "madra", plural: "madraí", audio_url: "https://example.com/a.mp3")
    vocabulary_items(:house).update!(part_of_speech: "noun")

    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_response :success
    assert_select "#gap-totals"
    assert_select "#gaps-lesson-#{item.lesson_id}", text: /teach/
    assert_select "#gap-item-#{item.id}", count: 0
    assert_select "#gap-item-#{vocabulary_items(:house).id}", text: /genitive, plural, and recording|genitive, plural and recording/
  end

  test "admins see lessons with no recordings" do
    VocabularyItem.delete_all
    item = VocabularyItem.create!(lesson: Lesson.first, irish: "x", english: "y")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_response :success
    assert_select "#silent-lessons a", text: /#{Regexp.escape(item.lesson.display_title)}/
  end

  test "a lesson with a recorded word is not listed as silent, and learners can't see the page" do
    VocabularyItem.delete_all
    item = VocabularyItem.create!(lesson: Lesson.first, irish: "x", english: "y", audio_url: "https://example.com/a.mp3")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#silent-lessons a", count: 0
    delete session_path
    get vocabulary_gaps_path
    assert_select "#silent-lessons", count: 0
  end

  test "admins see thin themes" do
    VocabularyItem.delete_all
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#thin-themes h2"
    assert_select "#thin-themes li", text: /Colours/
  end

  test "the report is read-only" do
    sign_in_as(users(:admin))
    assert_no_difference -> { VocabularyItem.count } do
      get vocabulary_gaps_path
    end
    assert_response :success
  end

  test "learners cannot see it" do
    sign_in_as(users(:two))
    get vocabulary_gaps_path
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get vocabulary_gaps_path
    assert_redirected_to new_session_path
  end

  test "lists words taught in more than one lesson" do
    other = Lesson.create!(number: 99, title: "Other", position: 99)
    other.vocabulary_items.create!(irish: "Madra", english: "dog again", position: 1)
    other.vocabulary_items.create!(irish: "Madra", english: "dog thrice", position: 2)

    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_response :success
    assert_select "#repeated-words li", text: /madra/i
    assert_select "#repeated-words li", count: 1
  end

  test "lists words used in an earlier lesson before the lesson that teaches them" do
    lessons(:one).update_columns(texts: "Feicim an capall.")
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    VocabularyItem.create!(lesson: two, irish: "capall", english: "horse", position: 1)

    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_response :success
    assert_select "#early-words li", count: 1
    assert_select "#early-words li span[lang=ga]", text: "capall"
    assert_select "#early-words li a[href=?]", edit_lesson_path(lessons(:one))
    assert_select "#early-words li a[href=?]", edit_lesson_path(two)
  end

  test "says so when no word is used before it's taught" do
    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_select "#early-words", text: /#{Regexp.escape(I18n.t("vocabulary_gaps.show.early_empty"))}/
  end

  test "unclassified words are listed separately and not counted as gaps" do
    vocabulary_items(:house).update!(audio_url: "https://example.com/h.mp3")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path

    assert_select "#unclassified h2", text: /still to classify/
    assert_select "#unclassified-item-#{vocabulary_items(:house).id}"
    assert_select "#gap-item-#{vocabulary_items(:house).id}", count: 0
  end

  test "an editor classifies a word in one tap, and it is recorded in history" do
    item = vocabulary_items(:house)
    sign_in_as(users(:admin))

    assert_difference -> { PaperTrail::Version.count }, 1 do
      patch vocabulary_item_part_of_speech_path(item), params: { part_of_speech: "noun" }
    end

    assert_equal "noun", item.reload.part_of_speech
    assert_redirected_to vocabulary_gaps_path(page: 1, anchor: "unclassified")
  end

  test "an invalid type is refused" do
    item = vocabulary_items(:house)
    sign_in_as(users(:admin))
    patch vocabulary_item_part_of_speech_path(item), params: { part_of_speech: "pronoun" }
    assert_nil item.reload.part_of_speech
  end

  test "learners cannot classify words" do
    item = vocabulary_items(:house)
    sign_in_as(users(:two))
    patch vocabulary_item_part_of_speech_path(item), params: { part_of_speech: "noun" }
    assert_redirected_to root_path
    assert_nil item.reload.part_of_speech
  end

  test "the lesson editor offers the type of each word" do
    sign_in_as(users(:admin))
    get edit_lesson_path(vocabulary_items(:house).lesson)
    assert_select "select[name$='[part_of_speech]']"
  end

  test "a missing type does not clear a classification" do
    item = vocabulary_items(:house)
    item.update!(part_of_speech: "noun")
    sign_in_as(users(:admin))
    patch vocabulary_item_part_of_speech_path(item), params: { part_of_speech: "" }
    assert_equal "noun", item.reload.part_of_speech
  end

  test "a page beyond the last is clamped" do
    sign_in_as(users(:admin))
    get vocabulary_gaps_path(page: 999)
    assert_response :success
    assert_select "#unclassified-item-#{vocabulary_items(:house).id}"
  end

  test "saving the word list with a blank type keeps an existing one; a chosen type is saved" do
    item = vocabulary_items(:house)
    item.update!(part_of_speech: "noun")
    sign_in_as(users(:admin))
    patch lesson_path(item.lesson), params: { lesson: { vocabulary_items_attributes: { "0" => { id: item.id, part_of_speech: "" } } } }
    assert_equal "noun", item.reload.part_of_speech
    patch lesson_path(item.lesson), params: { lesson: { vocabulary_items_attributes: { "0" => { id: item.id, part_of_speech: "verb" } } } }
    assert_equal "verb", item.reload.part_of_speech
  end

  test "admins see lessons with no exercises or phrases" do
    VocabularyItem.delete_all
    Exercise.delete_all
    Phrase.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#unpractised-lessons a", text: /#{Regexp.escape(lesson.display_title)}/
  end

  test "a lesson with a phrase is not listed as unpractised, and learners can't see the section" do
    VocabularyItem.delete_all
    Phrase.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    Phrase.create!(lesson: lesson, irish: "x", english: "y")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#unpractised-lessons a", count: 0
    delete session_path
    get vocabulary_gaps_path
    assert_select "#unpractised-lessons", count: 0
  end

  test "admins see lessons with no grammar notes, learners don't" do
    VocabularyItem.delete_all
    GrammarRule.destroy_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#ungrammared-lessons a", text: /#{Regexp.escape(lesson.display_title)}/
    delete session_path
    get vocabulary_gaps_path
    assert_select "#ungrammared-lessons", count: 0
  end

  test "admins see lessons with no listening clips; a lesson with a listed clip is not listed" do
    ListeningClip.delete_all
    VocabularyItem.delete_all
    a = Lesson.first
    b = Lesson.create!(number: 99, title: "Lesson Two", position: 99)
    VocabularyItem.create!(lesson: a, irish: "a", english: "one")
    item = VocabularyItem.create!(lesson: b, irish: "b", english: "two")
    ListeningClip.create!(vocabulary_item: item, abairt_entry_id: 1, irish: "x y z", english: "x y z", audio_url: "https://example.com/a.mp3", word_count: 3)
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#unlistened-lessons a", text: /#{Regexp.escape(a.display_title)}/
    assert_select "#unlistened-lessons a", text: /#{Regexp.escape(b.display_title)}/, count: 0
    delete session_path
    get vocabulary_gaps_path
    assert_select "#unlistened-lessons", count: 0
  end

  test "admins see lessons with no words; a lesson with a word is not listed" do
    VocabularyItem.delete_all
    a = Lesson.first
    b = Lesson.create!(number: 98, title: "Lesson Empty", position: 98)
    VocabularyItem.create!(lesson: a, irish: "a", english: "one")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#empty-lessons a", text: /#{Regexp.escape(b.display_title)}/
    assert_select "#empty-lessons a", text: /#{Regexp.escape(a.display_title)}/, count: 0
    delete session_path
    get vocabulary_gaps_path
    assert_select "#empty-lessons", count: 0
  end

  test "admins see lessons with recordings that have no speaker credit" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one", audio_url: "https://example.com/a.mp3")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#uncredited-lessons a", text: /#{Regexp.escape(lesson.display_title)}/
    assert_select "#uncredited-lessons", text: /1 recording with no speaker named/
  end

  test "admins see lessons with words that are not yet reviewed" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#unreviewed-lessons a", text: /#{Regexp.escape(lesson.display_title)}/
    lesson.mark_reviewed(by: users(:admin))
    get vocabulary_gaps_path
    assert_select "#unreviewed-lessons a", text: /#{Regexp.escape(lesson.display_title)}/, count: 0
  end

  test "admins see lessons with words but no reading text" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    lesson.text_passages.destroy_all
    lesson.update_columns(texts: nil)
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#unread-lessons a", text: /#{Regexp.escape(lesson.display_title)}/
  end

  test "admins see lessons with words that have no source note" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    sign_in_as(users(:admin))
    get vocabulary_gaps_path
    assert_select "#unsourced-lessons a", text: /#{Regexp.escape(lesson.display_title)}/
    VocabularyItem.update_all(source: "Erris p. 4")
    get vocabulary_gaps_path
    assert_select "#unsourced-lessons a", count: 0
  end
end
