require "test_helper"

class FocailFholaitheImportTest < ActiveSupport::TestCase
  def entry(position, headword, **fields)
    { "position" => position, "headword" => headword, "meaning_en" => nil, "meaning_ga" => nil, "usage" => nil,
      "alternative_forms" => nil, "pronunciation" => nil, "grammar_forms" => nil, "notes" => nil, "district" => nil }.merge(fields.stringify_keys)
  end

  def plan(*positions) = [ { "number" => 880, "title" => "Focail Fholaithe: Test", "positions" => positions } ]

  def entries
    [
      entry(1, "deascadh", meaning_en: "dregs, lees", grammar_forms: "plur. deascrachaí", district: "A' Fál Mór", pronunciation: "/ deskǝ /"),
      entry(2, "aithinne", meaning_en: "a live coal;", usage: "aithinne dearg, a red coal", alternative_forms: "aithne", grammar_forms: "an aithinne", notes: "Rare", district: "Ní fios"),
      entry(3, "cnuas", meaning_en: "a collection of scraps"),
      entry(4, "cnuas", meaning_en: "a crowd", usage: "cnuas daoine")
    ]
  end

  test "creates an unpublished thematic lesson with a source note and the words" do
    lesson = FocailFholaitheImport.new(entries:, plan: plan(1, 2)).call.first

    assert_equal 880, lesson.number
    assert_equal "thematic_vocab", lesson.lesson_type
    assert_not lesson.published?
    assert_equal [ "About this word list" ], lesson.lesson_blocks.map(&:caption)
    assert_includes lesson.lesson_blocks.first.body.to_plain_text, "Royal Irish Academy"
    assert_equal %w[deascadh aithinne], lesson.vocabulary_items.map(&:irish)
  end

  test "maps the source fields onto the word" do
    FocailFholaitheImport.new(entries:, plan: plan(1, 2)).call
    deascadh, aithinne = VocabularyItem.where(irish: %w[deascadh aithinne]).order(:id)

    assert_equal "dregs, lees", deascadh.english
    assert_equal "/deskǝ/", deascadh.phonetic
    assert_equal "deascrachaí", deascadh.plural
    assert_equal "Area: A' Fál Mór", deascadh.notes
    assert_nil deascadh.gender

    assert_equal "a live coal", aithinne.english
    assert_equal [ "In use: aithinne dearg, a red coal", "Also: aithne", "Forms: an aithinne", "Note: Rare" ], aithinne.notes.lines.map(&:chomp)
    assert_nil aithinne.plural
  end

  test "leaves out notes that are long scholarly passages" do
    long = entry(5, "urdubhán", meaning_en: "stormy petrel", alternative_forms: "x" * 501, usage: "short example")
    word = FocailFholaitheImport.new(entries: entries + [ long ], plan: plan(5)).call.first.vocabulary_items.sole

    assert_equal "In use: short example", word.notes
  end

  test "merges entries that share a headword into one word" do
    lesson = FocailFholaitheImport.new(entries:, plan: plan(3, 4)).call.first
    word = lesson.vocabulary_items.sole

    assert_equal "a collection of scraps; a crowd", word.english
    assert_equal "In use: cnuas daoine", word.notes
  end

  test "running again updates in place without duplicating" do
    FocailFholaitheImport.new(entries:, plan: plan(1, 2)).call
    changed = entries.map { |e| e["position"] == 1 ? e.merge("meaning_en" => "dregs") : e }
    lesson = FocailFholaitheImport.new(entries: changed, plan: plan(1, 2)).call.first

    assert_equal 1, Lesson.where(number: 880).count
    assert_equal 2, lesson.vocabulary_items.count
    assert_equal 1, lesson.lesson_blocks.count
    assert_equal "dregs", lesson.vocabulary_items.find_by(irish: "deascadh").english
    assert_not lesson.published?
  end

  test "refuses to overwrite a lesson that is not a Focail Fholaithe lesson" do
    Lesson.create!(number: 880, title: "The Copula", position: 880)

    assert_raises(FocailFholaitheImport::Conflict) { FocailFholaitheImport.new(entries:, plan: plan(1)).call }
    assert_equal "The Copula", Lesson.find_by(number: 880).title
  end

  test "fails loudly when the plan names an entry that does not exist" do
    assert_raises(KeyError) { FocailFholaitheImport.new(entries:, plan: plan(99)).call }
    assert_nil Lesson.find_by(number: 880)
  end
end
