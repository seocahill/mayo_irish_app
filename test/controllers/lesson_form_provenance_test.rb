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
      assert_select "span[title=?]", I18n.t("lessons.show.attested_in_abairt"), count: 1
    end
  end
end
