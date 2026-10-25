require "test_helper"

# Reviewing Abairt recordings for a lesson's words.
class RecordingSuggestionsTest < ActionDispatch::IntegrationTest
  ABAIRT = %r{\Ahttps://abairt\.com/api/transcriptions}

  setup do
    @lesson = lessons(:one)
    @item = vocabulary_items(:dog)
    sign_in_as(users(:admin))
  end

  def with_abairt_token(token = "t")
    previous = ENV["ABAIRT_API_TOKEN"]
    ENV["ABAIRT_API_TOKEN"] = token
    yield
  ensure
    ENV["ABAIRT_API_TOKEN"] = previous
  end

  def suggestion(id = 1, checked: true)
    @item.recording_suggestions.create!(abairt_entry_id: id, irish: @item.irish, audio_url: "https://clips.test/#{id}", speaker_name: "Speaker #{id}", check_passed: checked)
  end

  test "the review page lists the words without a recording, each loading its suggestions" do
    with_abairt_token { get lesson_recording_suggestions_path(@lesson) }

    assert_response :success
    assert_select "turbo-frame[src=?][loading=lazy]", vocabulary_item_recording_suggestions_path(@item)
  end

  test "a word's frame searches Abairt and checks the clips" do
    stub_request(:get, ABAIRT).to_return(status: 200, body: { entries: [
      { id: 7, word_or_phrase: @item.irish, translation: "dog", audio_url: "https://clips.test/7", speaker: { name: "A Speaker", dialect: "acaill" } }
    ] }.to_json)
    stub_request(:get, "https://clips.test/7").to_return(status: 200, body: "mp3-bytes")
    stub_request(:post, "https://api.abair.ie/v4/recognition/batch").to_return(status: 200, body: { text: @item.irish }.to_json)

    with_abairt_token { with_abair_key { get vocabulary_item_recording_suggestions_path(@item) } }

    assert_response :success
    assert_select "audio[src=?]", "https://clips.test/7"
    assert_select "p", text: I18n.t("vocabulary_item_recording_suggestions.index.check_passed")
    assert @item.recording_suggestions.sole.check_passed
  end

  test "says so when Abairt's limit is used up" do
    stub_request(:get, ABAIRT).to_return(status: 429)

    with_abairt_token { get vocabulary_item_recording_suggestions_path(@item) }

    assert_select "p", text: I18n.t("vocabulary_item_recording_suggestions.index.rate_limited")
    assert_nil @item.reload.recordings_searched_at
  end

  test "approving one gives the word that recording" do
    chosen = suggestion

    patch recording_suggestion_path(chosen), params: { status: "approved" }

    assert_redirected_to vocabulary_item_recording_suggestions_path(@item)
    assert_equal "https://clips.test/1", @item.reload.audio_url
  end

  test "rejecting one leaves the word as it was" do
    patch recording_suggestion_path(suggestion), params: { status: "rejected" }

    assert @item.recording_suggestions.sole.rejected?
    assert_nil @item.reload.audio_credit
  end

  test "approving all the checked ones at once" do
    suggestion(1)

    post lesson_recording_approval_path(@lesson)

    assert_redirected_to lesson_recording_suggestions_path(@lesson)
    assert_equal "Speaker 1", @item.reload.audio_credit
  end

  test "learners hear an approved recording, credited to the speaker" do
    suggestion.approve!(by: users(:admin))
    sign_in_as(users(:two))

    get lesson_path(@lesson)

    assert_select "audio[src=?]", "https://clips.test/1"
    assert_select "span", text: I18n.t("lessons.show.recorded_by", name: "Speaker 1")
  end

  test "only admins can review" do
    sign_in_as(users(:two))

    get lesson_recording_suggestions_path(@lesson)
    assert_redirected_to root_path

    patch recording_suggestion_path(suggestion), params: { status: "approved" }
    assert_nil @item.reload.audio_url
  end
end
