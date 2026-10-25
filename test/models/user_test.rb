require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "new users are not onboarded" do
    assert_not users(:newcomer).onboarded?
  end

  test "complete_onboarding saves the answers and marks the user onboarded" do
    user = users(:newcomer)

    assert user.complete_onboarding(place: " Belmullet ", dialect_region: "erris", door: "beginner")

    user.reload
    assert user.onboarded?
    assert_equal "Belmullet", user.place
    assert user.region_erris?
    assert user.door_beginner?
  end

  test "complete_onboarding needs a place, region and door" do
    user = users(:newcomer)

    assert_not user.complete_onboarding(place: "", dialect_region: nil, door: nil)

    assert_includes user.errors.attribute_names, :place
    assert_includes user.errors.attribute_names, :dialect_region
    assert_includes user.errors.attribute_names, :door
    assert_not user.reload.onboarded?
  end

  test "complete_onboarding rejects an unknown region" do
    user = users(:newcomer)

    assert_not user.complete_onboarding(place: "Ballina", dialect_region: "atlantis", door: "beginner")

    assert_includes user.errors.attribute_names, :dialect_region
  end

  test "other validations do not require onboarding answers" do
    assert users(:two).valid?
    assert users(:newcomer).valid?
  end
end
