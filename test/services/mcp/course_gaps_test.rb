require "test_helper"

class Mcp::CourseGapsTest < ActiveSupport::TestCase
  def call(**args)
    res = Mcp::Tools::CourseGaps.call(server_context: {}, **args)
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  setup do
    @one = lessons(:one)
    @empty = Lesson.create!(number: 2, title: "Empty", position: 2)
  end

  test "the whole course: each check with the lessons failing it, and the word totals" do
    _, data = call

    assert_equal Mcp::Tools::CourseGaps::CHECKS.keys.map(&:to_s), data["checks"].keys
    assert_equal [ 2 ], data["checks"]["no_words"]["lessons"].map { |l| l["number"] }
    assert_equal 1, data["checks"]["no_words"]["count"]
    assert_equal({ "number" => 1, "title" => "Lesson One", "words" => @one.vocabulary_items.count },
                 data["checks"]["no_recordings"]["lessons"].first)
    assert_equal [ 1 ], data["checks"]["words_without_source"]["lessons"].map { |l| l["number"] }
    assert_equal @one.vocabulary_items.count, data["words_missing"]["recording"]
    assert_kind_of Integer, data["words_not_classified"]
    assert_kind_of Array, data["thin_themes"]
  end

  test "a check that only counts some words gives how many" do
    vocabulary_items(:dog).update!(source: "Irish of Erris, p. 3")

    _, data = call

    assert_equal @one.vocabulary_items.count - 1, data["checks"]["words_without_source"]["lessons"].first["words"]
  end

  test "each check lists at most fifty lessons but counts them all" do
    (3..51).each { |n| Lesson.create!(number: n, title: "Empty #{n}", position: n) }

    _, data = call

    assert_equal 50, data["checks"]["no_words"]["count"]
    Lesson.create!(number: 52, title: "One more", position: 52)
    _, data = call
    assert_equal 51, data["checks"]["no_words"]["count"]
    assert_equal 50, data["checks"]["no_words"]["lessons"].size
  end

  test "recorded words with no speaker are counted per lesson, and lessons with words missing something are counted" do
    vocabulary_items(:dog).update!(audio_url: "https://example.org/madra.mp3")
    vocabulary_items(:house).update!(audio_url: "https://example.org/teach.mp3", audio_credit: "A Speaker")

    _, data = call

    assert_equal [ { "number" => 1, "title" => "Lesson One", "words" => 1 } ],
                 data["checks"]["recordings_without_speaker"]["lessons"]
    assert_equal 1, data["lessons_with_words_missing"]
  end

  test "draft lessons are included and say so" do
    draft = Lesson.create!(number: 7, title: "Draft", position: 7, published: false)

    _, data = call(lesson: 7)

    assert_equal false, data["lesson"]["published"]
    assert_includes data["fails"], "no_words"
    assert_includes call.last["checks"]["no_words"]["lessons"].map { |l| l["number"] }, draft.number
  end

  test "one lesson: the checks it fails, its words missing something, and words taught elsewhere" do
    item = vocabulary_items(:dog)
    item.update!(part_of_speech: "noun", genitive: "madra", audio_url: "https://example.org/madra.mp3")
    VocabularyItem.create!(lesson: @empty, irish: "Madra", english: "dog", position: 1)

    _, data = call(lesson: 1)

    assert_equal({ "number" => 1, "title" => "Lesson One", "published" => @one.published? }, data["lesson"])
    assert_includes data["fails"], "words_without_source"
    assert_not_includes data["fails"], "no_recordings"
    dog = data["words_missing"].find { |w| w["id"] == item.id }
    assert_equal [ "plural" ], dog["missing"]
    assert_equal [ { "irish" => "madra", "also_in_lessons" => [ 2 ] } ], data["also_taught_elsewhere"]
  end

  test "an empty lesson fails no_words and has nothing else to list" do
    _, data = call(lesson: 2)

    assert_includes data["fails"], "no_words"
    assert_empty data["words_missing"]
    assert_empty data["also_taught_elsewhere"]
  end

  test "the whole course lists words used before they're taught" do
    @one.update_columns(texts: "Feicim an capall.")
    VocabularyItem.create!(lesson: @empty, irish: "capall", english: "horse", position: 1)

    _, data = call

    assert_equal({ "count" => 1, "words" => [ { "id" => VocabularyItem.find_by(irish: "capall").id, "irish" => "capall", "english" => "horse",
                                                 "first_used_in_lesson" => 1, "taught_in_lesson" => 2 } ] },
                 data["used_before_taught"])
  end

  test "the course list of words used early stops at fifty but counts them all" do
    words = Array.new(52) { |i| "focal#{('a'.ord + i / 26).chr}#{('a'.ord + i % 26).chr}" }
    @one.update_columns(texts: words.join(" "))
    words.each_with_index { |w, i| VocabularyItem.create!(lesson: @empty, irish: w, english: "word", position: i) }

    _, data = call

    assert_equal 52, data["used_before_taught"]["count"]
    assert_equal Mcp::Tools::CourseGaps::EARLY_WORDS_LISTED, data["used_before_taught"]["words"].size
  end

  test "one lesson: the words it uses before they're taught, and the words it teaches that were used earlier" do
    @one.update_columns(texts: "Feicim an capall.")
    VocabularyItem.create!(lesson: @empty, irish: "capall", english: "horse", position: 1)
    horse = VocabularyItem.find_by(irish: "capall")
    entry = { "id" => horse.id, "irish" => "capall", "english" => "horse", "first_used_in_lesson" => 1, "taught_in_lesson" => 2 }

    _, first = call(lesson: 1)
    _, second = call(lesson: 2)

    assert_equal [ entry ], first["used_before_taught"]
    assert_empty first["taught_after_used"]
    assert_empty second["used_before_taught"]
    assert_equal [ entry ], second["taught_after_used"]
  end

  test "a lesson outside the curriculum has empty lists for words used before they're taught" do
    @one.update_columns(texts: "Feicim an capall.")
    theme = Lesson.create!(number: 3, title: "Animals", position: 3, lesson_type: "thematic_vocab")
    VocabularyItem.create!(lesson: theme, irish: "capall", english: "horse", position: 1)

    _, data = call(lesson: 3)

    assert_empty data["used_before_taught"]
    assert_empty data["taught_after_used"]
  end

  test "an unknown lesson number is an error" do
    res, = call(lesson: 999)

    assert res.error?
    assert_includes res.content.first[:text], "999"
    assert call(lesson: 0).first.error?
  end

  test "writes nothing" do
    assert_no_changes(-> { [ Lesson.count, VocabularyItem.count, VocabularyItem.maximum(:updated_at) ] }) do
      call
      call(lesson: 1)
    end
  end
end
