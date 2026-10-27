namespace :listening do
  desc "Find Abairt listening clips for the course's words, in course order, until Abairt's hourly limit; run again to carry on"
  task find: :environment do
    words = VocabularyItem.where(clips_searched_at: nil).joins(:lesson).merge(Lesson.curriculum)
                          .order("lessons.position", :position).to_a
    searched = 0

    words.each do |item|
      ListeningClipFinder.new(item).call
      searched += 1
    rescue AbairtClient::Error => e
      puts "Stopped: #{e.message}"
      break
    end

    puts "Searched #{searched} of #{words.size} words; #{ListeningClip.listed.count} clips listed in all."
  end
end
