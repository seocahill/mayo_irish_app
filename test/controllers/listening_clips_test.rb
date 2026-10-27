require "test_helper"

# Listening to Mayo speakers' phrases, and editors keeping an eye on them.
class ListeningClipsTest < ActionDispatch::IntegrationTest
  ABAIRT = %r{\Ahttps://abairt\.com/api/transcriptions}

  setup do
    @item = vocabulary_items(:dog)
    @clip = ListeningClip.create!(vocabulary_item: @item, abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                                  audio_url: "https://clips.test/1", speaker_name: "A Speaker", word_count: 3)
  end

  def with_abairt_token(token = "t")
    previous = ENV["ABAIRT_API_TOKEN"]
    ENV["ABAIRT_API_TOKEN"] = token
    yield
  ensure
    ENV["ABAIRT_API_TOKEN"] = previous
  end

  test "a learner hears the clip, with the words behind a reveal" do
    sign_in_as(users(:two))

    get listening_clip_path(@clip)

    assert_response :success
    assert_select "audio[src=?]", "https://clips.test/1"
    assert_select "details p[lang=ga]", text: "one madra two"
    assert_select "button", text: I18n.t("listening_clips.show.hide"), count: 0
  end

  test "saying whether they got it sets the clip aside" do
    sign_in_as(users(:two))

    post listening_clip_listen_path(@clip), params: { understood: false }

    assert_redirected_to root_path
    assert_not users(:two).listens.sole.understood
  end

  test "learners can't open a hidden clip" do
    @clip.hide!(by: users(:admin))
    sign_in_as(users(:two))

    get listening_clip_path(@clip)

    assert_response :not_found
  end

  test "an editor can hide a clip from learners, and list it again" do
    sign_in_as(users(:admin))

    patch listening_clip_path(@clip), params: { status: "hidden" }
    assert_redirected_to listening_clip_path(@clip)
    assert @clip.reload.hidden?

    patch listening_clip_path(@clip), params: { status: "listed" }
    assert @clip.reload.listed?
  end

  test "only editors can hide clips" do
    sign_in_as(users(:two))

    patch listening_clip_path(@clip), params: { status: "hidden" }

    assert @clip.reload.listed?
  end

  test "an editor sees each of a lesson's words loading its clips" do
    sign_in_as(users(:admin))

    with_abairt_token { with_abair_key { get lesson_listening_clips_path(lessons(:one)) } }

    assert_response :success
    assert_select "turbo-frame[src=?][loading=lazy]", vocabulary_item_listening_clips_path(@item)
  end

  test "a word's frame searches Abairt and keeps the clips the recogniser confirms" do
    house = vocabulary_items(:house)
    stub_request(:get, ABAIRT).to_return(status: 200, body: { entries: [
      { id: 7, word_or_phrase: "one teach two", translation: "a phrase", audio_url: "https://clips.test/7", speaker: { name: "A Speaker", dialect: "acaill" } }
    ] }.to_json)
    stub_request(:get, "https://clips.test/7").to_return(status: 200, body: "mp3-bytes")
    stub_request(:post, "https://api.abair.ie/v4/recognition/batch").to_return(status: 200, body: { text: "one teach two" }.to_json)
    sign_in_as(users(:admin))

    with_abairt_token { with_abair_key { get vocabulary_item_listening_clips_path(house) } }

    assert_response :success
    assert_select "audio[src=?]", "https://clips.test/7"
    assert_equal 7, house.listening_clips.sole.abairt_entry_id
  end
end
