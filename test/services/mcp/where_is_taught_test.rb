require "test_helper"

class Mcp::WhereIsTaughtTest < ActiveSupport::TestCase
  def call(word)
    res = Mcp::Tools::WhereIsTaught.call(word: word, server_context: {})
    [ res, (JSON.parse(res.content.first[:text]) unless res.error?) ]
  end

  test "finds a word by Irish or English with its lesson" do
    _, data = call("madra")
    assert_equal "madra", data["matches"].first["irish"]
    assert_equal 1, data["matches"].first["lesson"]["number"]
    _, data = call("DOG")
    assert_equal 1, data["matches"].size
  end

  test "counts quiz questions and phrases" do
    item = vocabulary_items(:dog)
    QuizQuestion.create!(lesson: item.lesson, source: item, direction: "ga_en", prompt: "madra", answer: "dog", distractors: [])
    Phrase.create!(lesson: item.lesson, irish: "Tá madra agam", english: "I have a dog")
    _, data = call("madra")
    assert_equal 1, data["matches"].first["quiz_questions"]
    assert_equal [ 1 ], data["used_in_phrases"].map { |l| l["number"] }
  end

  test "reports recordings, clips and exercise matches" do
    item = vocabulary_items(:dog)
    assert_not call("madra").last["matches"].first["has_recording"]
    item.update!(audio_url: "https://example.org/a.mp3")
    assert call("madra").last["matches"].first["has_recording"]
    Exercise.create!(lesson: item.lesson, number: 99, prompt: "Translate madra", answer: "dog")
    assert_equal [ 1 ], call("madra").last["used_in_exercises"].map { |l| l["number"] }
  end

  test "rejects blank input and treats wildcards literally" do
    assert call("").first.error?
    _, data = call("%%")
    assert_empty data["matches"]
  end

  test "writes nothing" do
    assert_no_changes(-> { [ VocabularyItem.count, Phrase.count, Lesson.count ] }) { call("madra") }
  end
end
