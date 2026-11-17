require "test_helper"

# Looking up attested plurals and genitives in Abairt for a noun, and accepting them.
class FormSuggestionsTest < ActionDispatch::IntegrationTest
  ABAIRT = %r{\Ahttps://abairt\.com/api/transcriptions}

  setup do
    @item = vocabulary_items(:dog)
    @item.update!(part_of_speech: "noun")
    sign_in_as(users(:admin))
    Rails.cache.clear
  end

  def stub_abairt(*entries)
    stub_request(:get, ABAIRT).to_return(status: 200, body: { entries: entries }.to_json)
  end

  def entry(id, text, speaker: "A", status: nil)
    { id: id, word_or_phrase: text, translation: "dogs", audio_url: "https://clips.test/#{id}", status: status, speaker: { name: speaker, dialect: "acaill" } }.compact
  end

  test "offers words taken from speech, confirmed and widely used first, unconfirmed labelled" do
    stub_abairt(entry(1, "Tá na madraí ag ithe", speaker: "A", status: "unconfirmed"),
                entry(2, "Chonaic mé madraí", speaker: "B"),
                entry(3, "Tá madraí agam", speaker: "C"),
                entry(4, "Níl aon ghnó agam"))
    with_abairt_token { get vocabulary_item_form_suggestions_path(@item) }

    assert_response :success
    assert_select "li", count: 3
    assert_select "li:first-child .text-foghlaim", text: /Confirmed/
    assert_select "li:last-child .text-labhair", text: /Not yet confirmed/
    assert_select "span[lang=ga]", text: "madraí", minimum: 3
    assert_select "span[lang=ga]", text: "madra", count: 0
  end

  test "keeps accents in the form and says when nothing matches" do
    stub_abairt(entry(1, "Tá madraí ann"))
    with_abairt_token { get vocabulary_item_form_suggestions_path(@item) }
    assert_select "span[lang=ga]", text: "madraí"

    stub_abairt(entry(2, "Tá teach ann"))
    Rails.cache.clear
    with_abairt_token { get vocabulary_item_form_suggestions_path(@item) }
    assert_select "li", count: 0
    assert_select "p", text: /No match in Abairt yet/
  end

  test "a used-up Abairt limit is reported, not raised" do
    stub_request(:get, ABAIRT).to_return(status: 429)
    with_abairt_token { get vocabulary_item_form_suggestions_path(@item) }
    assert_response :success
    assert_select "p.text-red-600"
  end

  test "accepting fills a blank plural with its source and is recorded in History" do
    assert_difference -> { PaperTrail::Version.where(item: @item).count }, 1 do
      post vocabulary_item_form_acceptance_path(@item), params: { kind: "plural", form: "madraí", entry_id: 2 }
    end
    @item.reload
    assert_equal "madraí", @item.plural
    assert_equal 2, @item.plural_source_entry_id
    assert_nil @item.genitive
  end

  test "accepting never overwrites a value" do
    @item.update!(plural: "madraí")
    post vocabulary_item_form_acceptance_path(@item), params: { kind: "plural", form: "madradh", entry_id: 3 }
    assert_equal "madraí", @item.reload.plural
    assert_nil @item.plural_source_entry_id
  end

  test "rejects anything that isn't one word" do
    post vocabulary_item_form_acceptance_path(@item), params: { kind: "genitive", form: "<b>x</b>" }
    assert_nil @item.reload.genitive
    post vocabulary_item_form_acceptance_path(@item), params: { kind: "name", form: "madra" }
    assert_response :redirect
  end

  test "a dismissed form isn't suggested again, once" do
    2.times { post vocabulary_item_form_dismissal_path(@item), params: { kind: "plural", form: "madraí" } }
    assert_equal 1, @item.form_suggestion_dismissals.count

    stub_abairt(entry(1, "Tá madraí ann"))
    with_abairt_token { get vocabulary_item_form_suggestions_path(@item) }
    assert_select "button", text: /Accept as plural/, count: 0
    assert_select "button", text: /Accept as genitive/, minimum: 1
  end

  test "learners can't use any of it" do
    delete session_path
    sign_in_as(users(:two))
    get vocabulary_item_form_suggestions_path(@item)
    assert_redirected_to root_path
    post vocabulary_item_form_acceptance_path(@item), params: { kind: "plural", form: "madraí" }
    assert_nil @item.reload.plural
  end

  test "the gaps report links to the lookup for nouns missing a form" do
    get vocabulary_gaps_path
    assert_select "#gap-item-#{@item.id} a[href=?]", vocabulary_item_form_suggestions_path(@item)
  end
end
