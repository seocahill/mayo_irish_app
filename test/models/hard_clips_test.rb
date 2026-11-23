require "test_helper"

class HardClipsTest < ActiveSupport::TestCase
  setup do
    @learner = users(:two)
    @other = User.create!(email_address: "three@example.com", password: "password123", approved: true)
  end

  def clip(entry_id, word_count: 3)
    ListeningClip.create!(vocabulary_item: vocabulary_items(:dog), abairt_entry_id: entry_id, irish: "one madra two",
                          english: "a phrase", audio_url: "https://clips.test/#{entry_id}", word_count: word_count)
  end

  test "clips learners couldn't make out come hardest first, with their figures" do
    half = clip(1)
    all = clip(2)
    made_out = clip(3)
    @learner.listens.create!(listening_clip: half, understood: false)
    @other.listens.create!(listening_clip: half, understood: true)
    @learner.listens.create!(listening_clip: all, understood: false)
    @learner.listens.create!(listening_clip: made_out, understood: true)

    rows = HardClips.new.rows

    assert_equal [ all, half ], rows.map(&:clip)
    assert_equal [ 2, 1, 50 ], [ rows.second.answers, rows.second.not_yet, rows.second.not_yet_percent ]
  end

  test "admins, unapproved learners and hidden clips are left out" do
    by_admin = clip(1)
    by_unapproved = clip(2)
    hidden = clip(3)
    users(:admin).listens.create!(listening_clip: by_admin, understood: false)
    users(:one).listens.create!(listening_clip: by_unapproved, understood: false)
    @learner.listens.create!(listening_clip: hidden, understood: false)
    hidden.update!(status: "hidden")

    assert_empty HardClips.new.rows
  end

  test "ties go to the shorter phrase, and the list is capped" do
    long = clip(1, word_count: 9)
    short = clip(2, word_count: 4)
    [ long, short ].each { |c| @learner.listens.create!(listening_clip: c, understood: false) }

    assert_equal [ short, long ], HardClips.new.rows.map(&:clip)
    assert_equal [ short ], HardClips.new(limit: 1).rows.map(&:clip)
  end

  test "a learner's latest answer is the one that counts" do
    later = clip(1)
    listen = @learner.listens.create!(listening_clip: later, understood: false)
    assert_equal [ later ], HardClips.new.rows.map(&:clip)

    listen.update!(understood: true)

    assert_empty HardClips.new.rows
  end
end
