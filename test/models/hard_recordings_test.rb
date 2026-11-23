require "test_helper"

class HardRecordingsTest < ActiveSupport::TestCase
  setup do
    @learner = users(:two)
    @other = User.create!(email_address: "three@example.com", password: "password123", approved: true)
  end

  def clip(entry_id, recording, title: "A Story", item: vocabulary_items(:dog), status: "listed")
    ListeningClip.create!(vocabulary_item: item, abairt_entry_id: entry_id, irish: "one madra two", english: "a phrase",
                          audio_url: "https://clips.test/#{entry_id}", word_count: 3, abairt_recording_id: recording,
                          abairt_recording_title: title, status: status)
  end

  def answer(user, recording, followed)
    user.listening_times.create!(abairt_recording_id: recording, seconds: 60, followed: followed)
  end

  test "conversations learners couldn't follow come hardest first, with their figures" do
    clip(1, 15, title: "Half")
    clip(2, 16, title: "All")
    clip(3, 17, title: "Followed")
    answer(@learner, 15, false)
    answer(@other, 15, true)
    answer(@learner, 16, false)
    answer(@learner, 17, true)
    answer(@other, 16, nil) # listened, never answered: not counted
    RecordingQuestion.create!(abairt_recording_id: 16, question: "Who is speaking?", answer: "A neighbour")

    rows = HardRecordings.new.rows

    assert_equal [ 16, 15 ], rows.map(&:recording_id)
    assert_equal [ "All", 1, 1, 1, 100 ], rows.first.then { |r| [ r.title, r.questions, r.answers, r.not_yet, r.not_yet_percent ] }
    assert_equal [ 2, 1, 50, 0 ], rows.second.then { |r| [ r.answers, r.not_yet, r.not_yet_percent, r.questions ] }
    assert_equal vocabulary_items(:dog).lesson, rows.first.lesson
  end

  test "each conversation is listed under the first lesson in the course that leads to it" do
    early = lessons(:one)
    late = Lesson.create!(number: 99, title: "Later", position: early.position.to_i + 50)
    later_item = late.vocabulary_items.create!(irish: "focal", english: "word")
    clip(1, 15, item: later_item)
    clip(2, 15, item: vocabulary_items(:dog))
    answer(@learner, 15, false)

    assert_equal early, HardRecordings.new.rows.sole.lesson
  end

  test "admins, unapproved learners and conversations no listed clip leads to are left out" do
    clip(1, 15)
    clip(2, 16)
    clip(3, 17, status: "hidden")
    answer(users(:admin), 15, false)
    answer(users(:one), 16, false)
    answer(@learner, 17, false)
    answer(@learner, 99, false)

    assert_empty HardRecordings.new.rows
  end

  test "a learner's latest answer is the one that counts" do
    clip(1, 15)
    time = answer(@learner, 15, false)
    assert_equal [ 15 ], HardRecordings.new.rows.map(&:recording_id)

    time.update!(followed: true)
    assert_empty HardRecordings.new.rows
  end

  test "the list is capped, and ties go to the earlier lesson" do
    late = Lesson.create!(number: 99, title: "Later", position: lessons(:one).position.to_i + 50)
    clip(1, 15, item: late.vocabulary_items.create!(irish: "focal", english: "word"))
    clip(2, 16)
    answer(@learner, 15, false)
    answer(@learner, 16, false)

    assert_equal [ 16 ], HardRecordings.new(limit: 1).rows.map(&:recording_id)
  end
end
