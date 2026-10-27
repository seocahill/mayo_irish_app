require "test_helper"

class ListeningClipTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @lesson = lessons(:one)
  end

  def clip(id, words: 3, item: vocabulary_items(:dog))
    ListeningClip.create!(vocabulary_item: item, abairt_entry_id: id, irish: "clip #{id}", english: "english #{id}",
                          audio_url: "https://clips.test/#{id}", word_count: words)
  end

  test "the next clip is the shortest one the learner hasn't listened to, from the given lessons" do
    long = clip(1, words: 8)
    short = clip(2, words: 4)

    assert_equal short, ListeningClip.next_for(@user, lessons: [ @lesson ])

    @user.listens.create!(listening_clip: short, understood: true)
    assert_equal long, ListeningClip.next_for(@user, lessons: [ @lesson ])
  end

  test "hidden clips and other lessons' clips aren't offered" do
    clip(1).hide!(by: users(:admin))
    clip(2)

    assert_nil ListeningClip.next_for(@user, lessons: [])
    assert_equal 2, ListeningClip.next_for(@user, lessons: [ @lesson ]).abairt_entry_id
  end

  test "a clip has to be a short phrase" do
    assert_raises(ActiveRecord::RecordInvalid) { clip(1, words: 1) }
    assert_raises(ActiveRecord::RecordInvalid) { clip(2, words: 20) }
  end
end
