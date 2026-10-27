require "test_helper"

class AbairtRecordingTest < ActiveSupport::TestCase
  # Stands in for AbairtClient.
  class Abairt
    def initialize(data) = @data = data

    def recording(_id) = @data
  end

  def data(lines: [ line("first", 3.7, "Speaker A"), line("second", 6.6, "Speaker B"), line("third", 9.1, "Speaker A") ])
    { "id" => 15, "title" => " A Story ", "audio_url" => "https://abairt.test/story.mp3", "dialect_region" => "erris", "lines" => lines }
  end

  def line(text, start, speaker) = { "irish" => text, "translation" => "#{text} in English", "start" => start, "end" => start + 2, "speaker" => { "name" => speaker } }

  test "reads the recording and its timed lines" do
    recording = AbairtRecording.find(15, abairt: Abairt.new(data))

    assert_equal "A Story", recording.title
    assert_equal [ 3.7, 6.6, 9.1 ], recording.lines.map(&:start)
    assert_equal "first in English", recording.lines.first.english
    assert_equal [ "Speaker A", "Speaker B" ], recording.speakers
  end

  test "groups the lines into turns by speaker, keeping uncredited lines in their turn" do
    lines = [ line("a", 1, "Speaker A"), line("b", 2, nil), line("c", 3, "Speaker A"), line("d", 4, "Speaker B"), line("e", 5, "Speaker A") ]
    lines[1]["speaker"] = nil

    turns = AbairtRecording.find(15, abairt: Abairt.new(data(lines: lines))).turns

    assert_equal [ %w[a b c], %w[d], %w[e] ], turns.map { |turn| turn.map(&:irish) }
  end

  test "something unexpected from Abairt is an Abairt error" do
    assert_raises(AbairtClient::Error) { AbairtRecording.find(15, abairt: Abairt.new({ "id" => 15 })) }
  end
end
