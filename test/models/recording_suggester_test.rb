require "test_helper"

class RecordingSuggesterTest < ActiveSupport::TestCase
  # Stands in for AbairtClient.
  class Abairt
    attr_reader :searches

    def initialize(entries) = (@entries = entries) && (@searches = 0)

    def recordings_of(_text) = (@searches += 1) && @entries
  end

  # Stands in for AbairClient: "hears" whatever the clip's URL says.
  class Abair
    def recognise(bytes, filename:) = bytes
  end

  setup do
    @item = vocabulary_items(:dog) # "madra"
  end

  def entry(id, irish, url: "https://clips.test/#{id}")
    stub_request(:get, url).to_return(status: 200, body: irish)
    { "id" => id, "word_or_phrase" => irish, "translation" => "english #{id}", "audio_url" => url, "speaker" => { "name" => "Speaker #{id}", "dialect" => "acaill" } }
  end

  def suggest(entries) = RecordingSuggester.new(@item, abairt: Abairt.new(entries), abair: Abair.new).call

  test "keeps entries that contain the word, the word on its own first, then the shortest phrases" do
    suggestions = suggest([ entry(1, "one two madra three"), entry(2, "madraí"), entry(3, "Madra"), entry(4, "one madra") ])

    assert_equal [ 3, 4, 1 ], suggestions.map(&:abairt_entry_id)
    assert_equal "Speaker 3", suggestions.first.speaker_name
  end

  test "suggests at most a few per word" do
    suggestions = suggest((1..6).map { |i| entry(i, "madra #{"x " * i}") })

    assert_equal RecordingSuggestion::PER_WORD, suggestions.size
  end

  test "checks each clip with the recogniser, and puts the ones that pass first" do
    good = entry(1, "madra")
    wrong = entry(2, "madra", url: "https://clips.test/wrong")
    stub_request(:get, "https://clips.test/wrong").to_return(status: 200, body: "something else")

    suggestions = suggest([ wrong, good ])

    assert_equal [ [ 1, true ], [ 2, false ] ], suggestions.map { |s| [ s.abairt_entry_id, s.check_passed ] }
    assert_equal "something else", suggestions.last.heard
  end

  test "a clip that can't be fetched is still suggested, unchecked" do
    broken = entry(1, "madra")
    stub_request(:get, broken["audio_url"]).to_return(status: 404)

    suggestion = suggest([ broken ]).sole

    assert_not suggestion.check_passed
    assert_nil suggestion.heard
  end

  test "follows redirects to the audio" do
    redirected = entry(1, "madra", url: "https://abairt.test/redirect")
    stub_request(:get, "https://abairt.test/redirect").to_return(status: 302, headers: { "Location" => "https://storage.test/clip" })
    stub_request(:get, "https://storage.test/clip").to_return(status: 200, body: "madra")

    assert suggest([ redirected ]).sole.check_passed
  end

  test "searches Abairt once per word, even when it finds nothing" do
    abairt = Abairt.new([])

    2.times { RecordingSuggester.new(@item, abairt: abairt, abair: Abair.new).call }

    assert_equal 1, abairt.searches
    assert @item.reload.recordings_searched_at
  end
end
