require "test_helper"

class LessonFormProvenanceTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:one)
    @item = @lesson.vocabulary_items.create!(irish: "madra", english: "dog", plural: "madraí", plural_source_entry_id: 5, genitive: "madra")
    sign_in_as(users(:two))
  end

  test "a plural taken from Abairt carries a marker; an unsourced genitive does not" do
    get lesson_path(@lesson)
    assert_response :success
    assert_select "tr", text: /madra.*madraí/m do
      assert_select "span[title=?]", I18n.t("lessons.show.attested_in_abairt"), count: 2 # desktop column and phone line
    end
  end

  test "genitive and plural are shown under the word on phones" do
    get lesson_path(@lesson)
    assert_select "div.md\\:hidden[data-test=forms-inline]", text: /gen\. madra.*pl\. madraí/m
  end

  test "phone line omits the separator for one form and renders nothing for none" do
    @lesson.vocabulary_items.create!(irish: "bó", english: "cow", plural: "ba")
    @lesson.vocabulary_items.create!(irish: "cat", english: "cat")
    get lesson_path(@lesson)
    assert_select "[data-test=forms-inline]", count: 2
    assert_select "[data-test=forms-inline]", text: /pl\. ba/ do |els|
      assert_no_match(/·/, els.first.text)
    end
  end
end
