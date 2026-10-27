require "test_helper"

class SpeechesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:two))
  end

  test "reads the text in the synthetic voice" do
    stub = stub_abair_synthesis(audio: "wav-bytes")

    with_abair_key { get speech_path(text: "  Tá   moill orm. ") }

    assert_response :success
    assert_equal "audio/wav", response.media_type
    assert_equal "wav-bytes", response.body
    assert_requested stub.with(body: hash_including("input" => "Tá moill orm."))
  end

  test "needs some text" do
    with_abair_key { get speech_path(text: " ") }

    assert_response :unprocessable_content
  end

  test "won't read more than a pronunciation's worth" do
    with_abair_key { get speech_path(text: "a" * (Pronunciation::MAX_CHARACTERS + 1)) }

    assert_response :unprocessable_content
  end

  test "says so when ABAIR can't be reached" do
    stub_abair_synthesis(status: 500)

    with_abair_key { get speech_path(text: "bád") }

    assert_response :bad_gateway
  end

  test "needs a signed-in user" do
    sign_out

    get speech_path(text: "bád")

    assert_redirected_to new_session_path
  end

  test "lesson pages offer speech for their Irish, once a key is set" do
    lesson = vocabulary_items(:dog).lesson

    with_abair_key { get lesson_path(lesson) }
    assert_select "[data-controller=speakable][data-speakable-src-value=?]", speech_path
    assert_select "[data-controller=speakable] [data-speakable-target=selection]"

    with_abair_key("") { get lesson_path(lesson) }
    assert_select "[data-controller=speakable]", count: 0
  end
end
