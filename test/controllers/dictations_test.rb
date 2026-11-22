require "test_helper"

class DictationsTest < ActionDispatch::IntegrationTest
  setup do
    @clip = ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: 1, irish: "one madra two", english: "a phrase",
                                  audio_url: "https://clips.test/1", speaker_name: "A Speaker", word_count: 3)
    sign_in_as(users(:two))
  end

  test "a clip offers type what you hear before the words are shown" do
    get listening_clip_path(@clip)

    assert_select "turbo-frame#dictation form[action=?]", listening_clip_dictation_path(@clip) do
      assert_select "textarea[name=heard][lang=ga][spellcheck=false][autocapitalize=off][aria-describedby=dictation-hint]"
      assert_select "label", text: I18n.t("dictations.form.label")
    end
  end

  test "checking lines the typed words up against the speaker's" do
    post listening_clip_dictation_path(@clip), params: { heard: "one modra" }, headers: { "Turbo-Frame" => "dictation" }

    assert_response :success
    assert_select "turbo-frame#dictation [data-testid=dictation-result]" do
      assert_select "[role=status]", text: I18n.t("dictations.frame.heard", count: 1, total: 3)
      assert_select "[data-status=heard]", text: "one"
      assert_select "[data-status=different]", text: /madra/
      assert_select "[data-status=different]", text: /modra/
      assert_select "[data-status=missed]", text: /two/
      assert_select "p", text: @clip.english
    end
    assert_select "turbo-frame#dictation textarea[name=heard]", text: "one modra"
  end

  test "inside the frame, only the frame comes back" do
    post listening_clip_dictation_path(@clip), params: { heard: "one" }, headers: { "Turbo-Frame" => "dictation" }

    assert_select "audio", count: 0
    assert_select "turbo-frame#dictation [data-testid=dictation-result] [role=status][autofocus]"
  end

  test "without JavaScript, the whole clip page comes back with the result in place" do
    post listening_clip_dictation_path(@clip), params: { heard: "one" }

    assert_select "audio[src=?]", @clip.audio_url
    assert_select "turbo-frame#dictation [data-testid=dictation-result]"
    assert_select "form[action=?]", listening_clip_listen_path(@clip), count: 2
  end

  test "what the learner typed is shown as text, never as markup" do
    post listening_clip_dictation_path(@clip), params: { heard: "<script>alert(1)</script> madra" }

    assert_select "script", text: "alert(1)", count: 0
    assert_select "textarea[name=heard]", text: "<script>alert(1)</script> madra"
  end

  test "an editor can check a hidden clip" do
    @clip.update!(status: "hidden")
    sign_in_as(users(:admin))

    post listening_clip_dictation_path(@clip), params: { heard: "one" }

    assert_response :success
  end

  test "needs a signed-in learner" do
    delete session_path
    post listening_clip_dictation_path(@clip), params: { heard: "one" }

    assert_redirected_to new_session_path
  end

  test "every word heard says so" do
    post listening_clip_dictation_path(@clip), params: { heard: "One madra two." }

    assert_select "[role=status]", text: I18n.t("dictations.frame.all_heard")
    assert_select "[data-status=missed], [data-status=different]", count: 0
  end

  test "nothing typed just shows the form again" do
    post listening_clip_dictation_path(@clip), params: { heard: "" }

    assert_select "[data-testid=dictation-result]", count: 0
    assert_select "turbo-frame#dictation textarea[name=heard]"
  end

  test "nothing is stored" do
    assert_no_difference -> { Listen.count } do
      post listening_clip_dictation_path(@clip), params: { heard: "one madra two" }
    end
  end

  test "a hidden clip can't be checked by a learner" do
    @clip.update!(status: "hidden")

    post listening_clip_dictation_path(@clip), params: { heard: "one" }

    assert_response :not_found
  end
end
