# A whole Abairt recording with its timed transcript, for a learner to listen
# through (see RecordingsController). Kept for a day: transcripts change
# rarely, and Abairt's hourly limit is shared by everyone using the course.
#
#   recording = AbairtRecording.find(15)
#   recording.lines.first  # => #<data Line start=3.7, end=6.4, irish="…", english="…", speaker="…">
class AbairtRecording
  Line = Data.define(:start, :end, :irish, :english, :speaker)

  attr_reader :id, :title, :audio_url, :dialect_region, :lines

  def self.find(id, abairt: AbairtClient.new)
    new(Rails.cache.fetch([ "abairt-recording", id.to_i ], expires_in: 1.day) { abairt.recording(id) })
  end

  def initialize(data)
    @id = data.fetch("id")
    @title = data["title"].to_s.squish
    @audio_url = data.fetch("audio_url")
    @dialect_region = data["dialect_region"]
    @lines = data.fetch("lines").map do |line|
      Line.new(start: line["start"].to_f, end: line["end"].to_f, irish: line["irish"].to_s.squish,
               english: line["translation"].to_s.squish.presence, speaker: line.dig("speaker", "name")&.squish)
    end
  rescue KeyError
    raise AbairtClient::Error, "Abairt returned something unexpected"
  end

  def speakers = lines.filter_map(&:speaker).uniq

  # The lines grouped into turns, one per change of speaker. A line nobody is
  # credited with stays in the turn it falls in.
  def turns
    speaker = lines.first&.speaker
    lines.slice_when do |_, line|
      (line.speaker.present? && line.speaker != speaker).tap { speaker = line.speaker || speaker }
    end.to_a
  end
end
