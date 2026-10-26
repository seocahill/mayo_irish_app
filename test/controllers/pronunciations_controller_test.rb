require "test_helper"

class PronunciationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @word = vocabulary_items(:dog)
    sign_in_as(users(:two))
  end

  test "plays the word in the synthetic voice" do
    stub = stub_abair_synthesis(audio: "wav-bytes")

    with_abair_key { get vocabulary_item_pronunciation_path(@word) }

    assert_response :success
    assert_equal "audio/wav", response.media_type
    assert_equal "wav-bytes", response.body
    assert_requested stub.with(body: hash_including("input" => @word.irish))
  end

  test "says so when ABAIR can't be reached" do
    stub_abair_synthesis(status: 500)

    with_abair_key { get vocabulary_item_pronunciation_path(@word) }

    assert_response :bad_gateway
  end

  test "says so when there is no key" do
    with_abair_key("") { get vocabulary_item_pronunciation_path(@word) }

    assert_response :bad_gateway
  end

  test "words in lessons learners can't see stay hidden" do
    @word.lesson.update!(published: false)

    with_abair_key { get vocabulary_item_pronunciation_path(@word) }

    assert_response :not_found
  end

  test "needs a signed-in user" do
    sign_out

    get vocabulary_item_pronunciation_path(@word)

    assert_redirected_to new_session_path
  end

  test "the lesson page offers a button for words without a recording, once a key is set" do
    with_abair_key { get lesson_path(@word.lesson) }
    assert_select "[data-controller=pronounce][data-pronounce-src-value=?]", vocabulary_item_pronunciation_path(@word)

    with_abair_key("") { get lesson_path(@word.lesson) }
    assert_select "[data-controller=pronounce]", count: 0
  end
end
