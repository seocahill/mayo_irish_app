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
end
