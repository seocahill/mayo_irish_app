require "test_helper"

class IrishTextTest < ActiveSupport::TestCase
  test "words ignore case, accents and punctuation" do
    assert_equal %w[ab cde fg], IrishText.words("Áb, CDÉ… fg!")
  end

  test "includes? matches whole words only" do
    assert IrishText.includes?("one Madra two", "madra")
    assert IrishText.includes?("one madra mór two", "madra mor")
    assert_not IrishText.includes?("madraí", "madra")
    assert_not IrishText.includes?("anything", "")
  end

  test "same? compares loosely" do
    assert IrishText.same?("Madra.", "madra")
    assert_not IrishText.same?("madra two", "madra")
  end
end
