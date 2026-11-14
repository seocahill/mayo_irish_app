require "test_helper"

class DialectSubstitutionsControllerTest < ActionDispatch::IntegrationTest
  test "admins can add, edit and remove a pair" do
    sign_in_as(users(:admin))

    assert_difference -> { DialectSubstitution.count }, 1 do
      post dialect_substitutions_path, params: { dialect_substitution: { other_form: "deacair", mayo_form: "doiligh" } }
    end
    pair = DialectSubstitution.last
    get dialect_substitutions_path
    assert_select "strong[lang=ga]", "doiligh"

    patch dialect_substitution_path(pair), params: { dialect_substitution: { note: "Mayo" } }
    assert_equal "Mayo", pair.reload.note

    assert_difference -> { DialectSubstitution.count }, -1 do
      delete dialect_substitution_path(pair)
    end
  end

  test "a pair needs both forms" do
    sign_in_as(users(:admin))

    post dialect_substitutions_path, params: { dialect_substitution: { other_form: "deacair" } }

    assert_response :unprocessable_entity
  end

  test "the lesson editor points out where the other form appears" do
    lesson = lessons(:one)
    lesson.vocabulary_items.create!(irish: "deacair", english: "difficult", gender: "m")
    DialectSubstitution.create!(other_form: "deacair", mayo_form: "doiligh")
    sign_in_as(users(:admin))

    get edit_lesson_path(lesson)

    assert_select "#dialect-hits-heading"
  end

  test "learners and visitors are kept out" do
    get dialect_substitutions_path
    assert_redirected_to new_session_path

    sign_in_as(users(:two))
    get dialect_substitutions_path
    assert_redirected_to root_path
  end
end
