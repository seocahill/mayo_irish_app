require "test_helper"

class VocabularyGapsTest < ActiveSupport::TestCase
  test "a complete word is not listed and a blank audio_url counts as missing" do
    item = vocabulary_items(:dog)
    item.update!(genitive: "madra", plural: "madraí", audio_url: "")
    assert_equal [ :recording ], VocabularyGaps.missing_for(item)
    item.update!(audio_url: "https://example.com/a.mp3")
    assert_empty VocabularyGaps.missing_for(item)
    assert_not_includes VocabularyGaps.new.rows.flat_map(&:items), item
  end

  test "totals count each kind of gap" do
    totals = VocabularyGaps.new.totals
    assert_equal 0, totals[:genitive], "unclassified words are not counted as genitive gaps"
    vocabulary_items(:house).update!(part_of_speech: "noun")
    totals = VocabularyGaps.new.totals
    assert_equal 1, totals[:genitive]
    assert_equal 1, totals[:plural]
  end

  test "only nouns can lack a genitive or plural" do
    item = vocabulary_items(:dog)
    item.update!(audio_url: "https://example.com/a.mp3", genitive: "", plural: "")
    assert_empty VocabularyGaps.missing_for(item)
    %w[verb adjective adverb other].each do |kind|
      item.update!(part_of_speech: kind)
      assert_empty VocabularyGaps.missing_for(item)
    end
    item.update!(part_of_speech: "noun")
    assert_equal [ :genitive, :plural ], VocabularyGaps.missing_for(item)
  end

  test "part of speech validates and blank stays empty" do
    item = vocabulary_items(:dog)
    item.part_of_speech = "pronoun"
    assert_not item.valid?
    item.part_of_speech = ""
    assert item.valid?
    assert_nil item.tap(&:save!).reload.part_of_speech
  end

  test "whole words match, plurals count, substrings do not" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "tired")
    VocabularyItem.create!(lesson: lesson, irish: "b", english: "Reds")
    colours = VocabularyGaps.new.thin_themes.find { |t| t.name == "Colours" }
    assert_equal 1, colours.count
  end

  test "a theme with three words drops off, two stay, thinnest first" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    %w[red green].each_with_index { |c, i| VocabularyItem.create!(lesson: lesson, irish: "x#{i}", english: c) }
    themes = VocabularyGaps.new.thin_themes
    assert_equal 2, themes.find { |t| t.name == "Colours" }.count
    assert_equal themes.map(&:count), themes.map(&:count).sort
    VocabularyItem.create!(lesson: lesson, irish: "x9", english: "blue")
    assert_nil VocabularyGaps.new.thin_themes.find { |t| t.name == "Colours" }
  end

  test "themes file is well formed" do
    raw = YAML.safe_load_file(VocabularyGaps::THEMES_FILE)
    assert raw.all? { |t| t["name"].present? && t["keywords"].present? && t["keywords"].all?(String) }
    assert_equal raw.size, raw.map { |t| t["name"] }.uniq.size
  end

  test "a lesson is silent only when none of its words has a recording" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    a = VocabularyItem.create!(lesson: lesson, irish: "a", english: "one", audio_url: "")
    VocabularyItem.create!(lesson: lesson, irish: "b", english: "two")
    assert_equal [ [ lesson, 2 ] ], VocabularyGaps.new.silent_lessons.map { |s| [ s.lesson, s.count ] }
    a.update!(audio_url: "https://example.com/a.mp3")
    assert_empty VocabularyGaps.new.silent_lessons
  end

  test "a lesson is unpractised only when it has words but no exercises or phrases" do
    VocabularyItem.delete_all
    Exercise.delete_all
    Phrase.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.unpractised_lessons.map { |u| [ u.lesson, u.count ] }
    Phrase.create!(lesson: lesson, irish: "x", english: "y")
    assert_empty VocabularyGaps.new.unpractised_lessons
  end

  test "a lesson is listed as having no grammar only when it has words and no grammar rules" do
    VocabularyItem.delete_all
    GrammarRule.destroy_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.ungrammared_lessons.map { |u| [ u.lesson, u.count ] }
    GrammarRule.create!(lesson: lesson, number: 1, title: "Rule")
    assert_empty VocabularyGaps.new.ungrammared_lessons
  end

  test "a lesson is listed as having no listening clips unless a word has a listed clip" do
    ListeningClip.delete_all
    VocabularyItem.delete_all
    lesson = Lesson.first
    assert_empty VocabularyGaps.new.unlistened_lessons
    item = VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.unlistened_lessons.map { |u| [ u.lesson, u.count ] }
    clip = ListeningClip.create!(vocabulary_item: item, abairt_entry_id: 1, irish: "x y z", english: "x y z", audio_url: "https://example.com/a.mp3", word_count: 3, status: "hidden")
    assert_equal 1, VocabularyGaps.new.unlistened_lessons.size
    clip.listed!
    assert_empty VocabularyGaps.new.unlistened_lessons
  end

  test "a lesson is listed as uncredited when a recorded word has no named speaker" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    assert_empty VocabularyGaps.new.uncredited_lessons
    recorded = VocabularyItem.create!(lesson: lesson, irish: "b", english: "two", audio_url: "https://example.com/b.mp3")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.uncredited_lessons.map { |u| [ u.lesson, u.count ] }
    recorded.update!(audio_credit: "Máire")
    assert_empty VocabularyGaps.new.uncredited_lessons
  end

  test "an uploaded recording with no speaker credit is listed as uncredited" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    item = VocabularyItem.create!(lesson: lesson, irish: "c", english: "three")
    item.audio.attach(io: StringIO.new("x"), filename: "c.mp3", content_type: "audio/mpeg")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.uncredited_lessons.map { |u| [ u.lesson, u.count ] }
  end

  test "a lesson with words is listed as unreviewed until it is marked reviewed" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    assert_empty VocabularyGaps.new.unreviewed_lessons.select { |u| u.lesson == lesson }
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    assert_includes VocabularyGaps.new.unreviewed_lessons.map(&:lesson), lesson
    lesson.mark_reviewed(by: users(:admin))
    assert_not_includes VocabularyGaps.new.unreviewed_lessons.map(&:lesson), lesson
  end

  test "a lesson with words but no reading text is listed as unread" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    lesson.text_passages.destroy_all
    lesson.update_columns(texts: nil)
    assert_empty VocabularyGaps.new.unread_lessons
    VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.unread_lessons.map { |u| [ u.lesson, u.count ] }
    lesson.update_columns(texts: "A short text")
    assert_empty VocabularyGaps.new.unread_lessons
    lesson.text_passages.destroy_all
    lesson.update_columns(texts: nil)
    lesson.text_passages.create!(title: "Passage")
    assert_empty VocabularyGaps.new.unread_lessons
  end

  test "a lesson with words lacking a source note is listed as unsourced" do
    VocabularyItem.delete_all
    lesson = Lesson.first
    item = VocabularyItem.create!(lesson: lesson, irish: "a", english: "one")
    VocabularyItem.create!(lesson: lesson, irish: "b", english: "two", source: "Erris p. 4")
    assert_equal [ [ lesson, 1 ] ], VocabularyGaps.new.unsourced_lessons.map { |u| [ u.lesson, u.count ] }
    item.update!(source: "Tourmakeady p. 9")
    assert_empty VocabularyGaps.new.unsourced_lessons
  end
  test "a word taught later that already turns up in an earlier lesson's text, phrases or exercises is listed" do
    one = lessons(:one)
    one.text_passages.destroy_all
    one.update_columns(texts: "Tá BAD mór sa pháirc.")
    one.phrases.create!(irish: "ar an gcnoc", english: "on the hill")
    one.exercises.create!(number: 2, prompt: "Cuir Gaeilge air", answer: "fear an tí", position: 2)
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    VocabularyItem.create!(lesson: two, irish: "bád", english: "boat", position: 1)
    VocabularyItem.create!(lesson: two, irish: "cnoc", english: "hill", position: 2)
    VocabularyItem.create!(lesson: two, irish: "fear an tí", english: "man of the house", position: 3)
    VocabularyItem.create!(lesson: two, irish: "an", english: "the", position: 4)
    VocabularyItem.create!(lesson: two, irish: "páirc", english: "field", position: 5)

    early = VocabularyGaps.new.early_words

    assert_equal [ "bád", "fear an tí" ], early.map { |e| e.item.irish }, "accents and case aside; two-letter words and mutated forms are not matched"
    assert early.all? { |e| e.used_in == one && e.taught_in == two }
  end

  test "a word taught in an earlier lesson too, or only used later, is not listed" do
    one = lessons(:one)
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    two.update_columns(texts: "madra mór agus capall")
    VocabularyItem.create!(lesson: two, irish: "capall", english: "horse", position: 1)
    three = Lesson.create!(number: 3, title: "Lesson Three", position: 3)
    VocabularyItem.create!(lesson: three, irish: "madra", english: "dog", position: 1)
    one.update_columns(texts: "Níl aon rud anseo.")

    assert_empty VocabularyGaps.new.early_words, "madra is first taught in lesson one; capall is used where it's taught"
  end

  test "only curriculum lessons count" do
    lessons(:one).update_columns(texts: "Feicim an capall.", lesson_type: "thematic_vocab")
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    VocabularyItem.create!(lesson: two, irish: "capall", english: "horse", position: 1)

    assert_empty VocabularyGaps.new.early_words
  end
  test "a reading passage counts, and quote marks around speech don't hide its first and last words" do
    one = lessons(:one)
    one.text_passages.create!(title: "Scéal", body: "<p>'Tá an capall tuirseach,' a dúirt sé.</p>")
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    VocabularyItem.create!(lesson: two, irish: "tuirseach", english: "tired", position: 1)
    VocabularyItem.create!(lesson: two, irish: "dúirt", english: "said", position: 2)

    assert_equal [ "dúirt", "tuirseach" ], VocabularyGaps.new.early_words.map { |e| e.item.irish }
  end

  test "notes in brackets are dropped and alternatives are each matched, once per word" do
    lessons(:one).update_columns(texts: "Bhí súil agam leis. Mise agus tusa.")
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    VocabularyItem.create!(lesson: two, irish: "súil (le)", english: "hope", position: 1)
    VocabularyItem.create!(lesson: two, irish: "mé, mise", english: "me", position: 2)
    VocabularyItem.create!(lesson: two, irish: "tusa/tú", english: "you", position: 3)

    assert_equal [ "mé, mise", "súil (le)", "tusa/tú" ], VocabularyGaps.new.early_words.map { |e| e.item.irish }
  end

  test "in exercises, often written in English, the fadas must match" do
    lessons(:one).exercises.create!(number: 2, prompt: "Translate: there is too much water. Múch an solas.", position: 2)
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 2)
    VocabularyItem.create!(lesson: two, irish: "múch", english: "extinguish", position: 1)
    VocabularyItem.create!(lesson: two, irish: "solas", english: "light", position: 2)
    VocabularyItem.create!(lesson: two, irish: "too", english: "not Irish", position: 3)

    early = VocabularyGaps.new.early_words.map { |e| e.item.irish }
    assert_equal [ "múch", "solas", "too" ], early
    lessons(:one).exercises.last.update!(prompt: "Translate: there is too much water.")
    assert_equal [ "too" ], VocabularyGaps.new.early_words.map { |e| e.item.irish }, "much is not múch"
  end

  test "a word taught in lessons one and three and used in two is not listed; lessons sharing a position go by number" do
    lessons(:one).update_columns(position: 5)
    two = Lesson.create!(number: 2, title: "Lesson Two", position: 5, texts: "Tá madra agus cathaoir anseo.")
    three = Lesson.create!(number: 3, title: "Lesson Three", position: 6)
    VocabularyItem.create!(lesson: three, irish: "madra", english: "dog", position: 1)
    VocabularyItem.create!(lesson: three, irish: "cathaoir", english: "chair", position: 2)

    early = VocabularyGaps.new.early_words
    assert_equal [ "cathaoir" ], early.map { |e| e.item.irish }, "madra is first taught in lesson one"
    assert_equal two, early.first.used_in
  end

  test "whole conversations with no questions to listen for are listed under the first lesson that leads to each" do
    ListeningClip.delete_all
    VocabularyItem.delete_all
    first = Lesson.first
    later = Lesson.create!(number: 97, title: "Later", position: first.position.to_i + 50)
    early_item = VocabularyItem.create!(lesson: first, irish: "a", english: "one")
    later_item = VocabularyItem.create!(lesson: later, irish: "b", english: "two")
    clip = ->(item, entry, recording, title, status: "listed") do
      ListeningClip.create!(vocabulary_item: item, abairt_entry_id: entry, irish: "x y z", english: "x y z", audio_url: "https://example.com/#{entry}.mp3",
                            word_count: 3, abairt_recording_id: recording, abairt_recording_title: title, status: status)
    end
    clip.(later_item, 1, 15, "A Story")
    clip.(early_item, 2, 15, "A Story")
    clip.(later_item, 3, 16, "")
    clip.(later_item, 4, 17, "Hidden one", status: "hidden")
    clip.(later_item, 5, nil, nil)

    rows = VocabularyGaps.new.unquestioned_lessons
    assert_equal [ [ first, [ [ 15, "A Story" ] ] ], [ later, [ [ 16, nil ] ] ] ], rows.map { |r| [ r.lesson, r.recordings.map { |rec| [ rec.id, rec.title ] } ] }
    assert_equal [ 1, 1 ], rows.map(&:count)

    RecordingQuestion.create!(abairt_recording_id: 15, question: "Q", answer: "A")
    assert_equal [ later ], VocabularyGaps.new.unquestioned_lessons.map(&:lesson)
  end
end
