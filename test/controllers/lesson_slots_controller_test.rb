require "test_helper"

class LessonSlotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:one)
    @lesson.update!(published: false)
    sign_in_as(users(:admin))
  end

  test "an admin adds a slot to a draft and sees it on the edit page" do
    assert_difference -> { @lesson.lesson_slots.count } do
      post lesson_slots_path(@lesson), params: { lesson_slot: { slot_type: "phrases", spec: "Greetings for the morning" } }
    end

    slot = @lesson.lesson_slots.sole
    assert_equal [ "phrases", "open", "admin@example.com" ], [ slot.slot_type, slot.status, slot.created_by ]
    assert_redirected_to edit_lesson_path(@lesson, anchor: "slots")

    get edit_lesson_path(@lesson)
    assert_select "##{ActionView::RecordIdentifier.dom_id(slot)}", text: /Greetings for the morning/
    assert_select "[data-open-slots='1']"
  end

  test "a blank spec isn't saved and says why" do
    assert_no_difference -> { LessonSlot.count } do
      post lesson_slots_path(@lesson), params: { lesson_slot: { slot_type: "phrases", spec: "" } }
    end
    assert flash[:alert].present?
  end

  test "slots can't be added to a published lesson" do
    @lesson.update!(published: true)

    assert_no_difference -> { LessonSlot.count } do
      post lesson_slots_path(@lesson), params: { lesson_slot: { slot_type: "phrases", spec: "Greetings" } }
    end
    assert_equal I18n.t("lesson_slots.create.published"), flash[:alert]

    get edit_lesson_path(@lesson)
    assert_select "#slots", count: 0
  end

  test "removing a slot marks it removed and it leaves the list" do
    slot = @lesson.lesson_slots.create!(slot_type: "dialogue", spec: "A short dialogue at the shop")

    assert_no_difference -> { LessonSlot.count } do
      delete slot_path(slot)
    end

    assert_equal [ "removed", "admin@example.com" ], slot.reload.values_at(:status, :removed_by)
    get edit_lesson_path(@lesson)
    assert_select "##{ActionView::RecordIdentifier.dom_id(slot)}", count: 0
    assert_select "[data-open-slots]", count: 0

    delete slot_path(slot)
    assert_equal I18n.t("lesson_slots.destroy.already_removed"), flash[:notice]
  end

  test "ticking Published with an open slot is refused and says how many are open" do
    @lesson.lesson_slots.create!(slot_type: "vocabulary", spec: "Weather words")

    patch lesson_path(@lesson), params: { lesson: { published: "1" } }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /1 slot is open/
    assert_select "#slots form[action=?]", lesson_slots_path(@lesson)
    assert_not @lesson.reload.published?
  end

  test "learners can't add or remove slots" do
    slot = @lesson.lesson_slots.create!(slot_type: "dialogue", spec: "A dialogue")
    sign_in_as(users(:two))

    assert_no_difference -> { LessonSlot.count } do
      post lesson_slots_path(@lesson), params: { lesson_slot: { slot_type: "phrases", spec: "x" } }
    end
    delete slot_path(slot)

    assert_predicate slot.reload, :open?
  end
end
