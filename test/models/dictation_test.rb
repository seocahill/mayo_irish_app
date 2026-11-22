require "test_helper"

class DictationTest < ActiveSupport::TestCase
  def statuses(transcript, typed) = Dictation.new(transcript, typed).words.map { [ it.text, it.status ] }

  test "every word typed is every word heard, whatever the case and punctuation" do
    dictation = Dictation.new("Tá an madra ag rith, thart!", "tá AN madra ag rith thart")

    assert dictation.all_heard?
    assert_equal 6, dictation.heard_count
    assert_equal %w[Tá an madra ag rith thart], dictation.words.map(&:text), "the speaker's words are shown as written"
  end

  test "a missing fada counts as heard, and is pointed out" do
    word = Dictation.new("Tá sé fuar", "ta se fuar").words.first

    assert word.heard?
    assert word.fada_missing?
    assert Dictation.new("Tá sé fuar", "ta se fuar").all_heard?
    assert_not Dictation.new("Tá sé fuar", "Tá sé fuar").words.first.fada_missing?
    assert_not Dictation.new("ta", "tá").words.first.fada_missing?, "an extra fada isn't a missing one"
  end

  test "a word left out is missed" do
    assert_equal [ [ "Tá", :heard ], [ "an", :missed ], [ "madra", :heard ] ], statuses("Tá an madra", "tá madra")
  end

  test "a word heard as something else is different, with what was typed" do
    words = Dictation.new("Tá an madra mór", "tá an mada mór").words

    assert_equal %i[heard heard different heard], words.map(&:status)
    assert_equal "mada", words.third.typed
  end

  test "extra words typed don't take a speaker's word" do
    assert_equal [ [ "Tá", :heard ], [ "sé", :heard ] ], statuses("Tá sé", "tá go sé maith")
  end

  test "more speaker words than typed in a gap: the first are different, the rest missed" do
    assert_equal [ [ "a", :heard ], [ "b", :different ], [ "c", :missed ], [ "d", :heard ] ], statuses("a b c d", "a x d")
  end

  test "nothing typed: not attempted, nothing heard" do
    dictation = Dictation.new("Tá an madra", "   ")

    assert_not dictation.attempted?
    assert_not dictation.all_heard?
    assert_equal %i[missed missed missed], dictation.words.map(&:status)
  end

  test "an apostrophe or hyphen inside a word is kept" do
    assert_equal [ [ "d'ól", :heard ], [ "t-uisce", :heard ] ], statuses("d'ól t-uisce", "d'ol t-uisce")
  end

  test "a very long answer is cut short" do
    dictation = Dictation.new("Tá", "tá " + ("x " * 1000))

    assert dictation.all_heard?
  end
end
