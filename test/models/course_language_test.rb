require "test_helper"

class CourseLanguageTest < ActiveSupport::TestCase
  setup do
    @language = CourseLanguage.new(irish: [ "Tá Cáit thuas", "níos fearr", "maith", "an bord" ],
                                   english: [ "up, above", "better", "good", "the table", "an apple" ])
  end

  test "goes by the words it knows from each language" do
    assert_equal :irish, @language.of("níos/is fearr")
    assert_equal :english, @language.of("up, upwards")
  end

  test "words found in both languages don't count" do
    assert_equal :irish, @language.of("an bord")
    assert_equal :english, @language.of("an apple")
  end

  test "a fada tips an unknown word towards Irish" do
    assert_equal :irish, @language.of("álainn")
    assert_nil @language.of("tiubh")
  end

  test "the current course's words" do
    assert_equal :irish, CourseLanguage.current.of(vocabulary_items(:dog).irish)
    assert_equal :english, CourseLanguage.current.of(vocabulary_items(:dog).english)
  end
end
