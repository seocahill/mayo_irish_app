require "test_helper"

class PronunciationTest < ActiveSupport::TestCase
  Client = Struct.new(:calls) do
    def synthesise(text) = (calls << text) && "wav:#{text}"
  end

  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
    @original_cache = Rails.cache
    Rails.cache = @cache
  end

  teardown { Rails.cache = @original_cache }

  test "returns the synthesised audio" do
    assert_equal "wav:an bád", Pronunciation.new("an bád", client: Client.new([])).audio
  end

  test "asks ABAIR once per text" do
    client = Client.new([])

    2.times { Pronunciation.new("an bád", client: client).audio }

    assert_equal [ "an bád" ], client.calls
  end

  test "tidies whitespace and caps the length" do
    client = Client.new([])

    Pronunciation.new("  an   bád ", client: client).audio
    Pronunciation.new("x" * 1000, client: client).audio

    assert_equal [ "an bád", "x" * Pronunciation::MAX_CHARACTERS ], client.calls
  end
end
