require "test_helper"

class ListeningClipFinderTest < ActiveSupport::TestCase
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

  def entry(id, irish, url: "https://clips.test/#{id}", translation: "english #{id}")
    stub_request(:get, url).to_return(status: 200, body: irish)
    { "id" => id, "word_or_phrase" => irish, "translation" => translation, "audio_url" => url, "speaker" => { "name" => "Speaker #{id}", "dialect" => "acaill" } }
  end

  def find(entries, item: @item) = ListeningClipFinder.new(item, abairt: Abairt.new(entries), abair: Abair.new).call

  test "keeps the shortest phrases that use the word, not the word on its own" do
    clips = find([ entry(1, "one two madra three four"), entry(2, "madra"), entry(3, "one madra two"), entry(4, "one two madra three") ])

    assert_equal [ 3, 4 ], clips.map(&:abairt_entry_id)
    assert_equal [ 3, 4 ], clips.map(&:word_count)
    assert_equal "Speaker 3", clips.first.speaker_name
  end

  test "leaves out phrases that are too long, untranslated, or don't use the word" do
    clips = find([ entry(1, "madra #{"x " * 12}"), entry(2, "one madra two", translation: ""), entry(3, "one madraí two"), entry(4, "one two three") ])

    assert_empty clips
  end

  test "keeps only clips the recogniser hears the word in" do
    wrong = entry(1, "one madra two", url: "https://clips.test/wrong")
    stub_request(:get, "https://clips.test/wrong").to_return(status: 200, body: "something else entirely")
    broken = entry(2, "one madra two three")
    stub_request(:get, broken["audio_url"]).to_return(status: 404)

    clip = find([ wrong, broken, entry(3, "one two madra three four") ]).sole

    assert_equal 3, clip.abairt_entry_id
    assert_equal "one two madra three four", clip.heard
  end

  test "keeps only clips in which the recogniser hears most of the phrase" do
    off = entry(1, "one madra two three four", url: "https://clips.test/off")
    stub_request(:get, "https://clips.test/off").to_return(status: 200, body: "one madra else entirely here")

    clip = find([ off, entry(2, "one two madra three four five") ]).sole

    assert_equal 2, clip.abairt_entry_id
  end

  test "leaves a phrase already kept for another word to that word" do
    find([ entry(1, "one madra teach") ], item: vocabulary_items(:house))

    assert_empty find([ entry(1, "one madra teach") ])
  end

  test "searches Abairt once per word, even when it finds nothing" do
    abairt = Abairt.new([])

    2.times { ListeningClipFinder.new(@item, abairt: abairt, abair: Abair.new).call }

    assert_equal 1, abairt.searches
    assert @item.reload.clips_searched_at
  end
end
