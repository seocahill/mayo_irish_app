namespace :intro_videos do
  desc "Give lessons that have no intro video a placeholder video (LESSONS=3,4 to choose, LIMIT=5 otherwise)"
  task placeholders: :environment do
    placeholder_url = "https://assets.abairt.com/darren-reagan-bofield.mp4"

    scope = Lesson.where(intro_video_url: [ nil, "" ])
    scope = if ENV["LESSONS"].present?
      scope.where(number: ENV["LESSONS"].split(",").map(&:to_i))
    else
      scope.curriculum.joins(:vocabulary_items).distinct.ordered.limit(ENV.fetch("LIMIT", 5).to_i)
    end

    scope.each do |lesson|
      lesson.update!(intro_video_url: placeholder_url)
      puts "Lesson #{lesson.number}: #{lesson.title}"
    end
    puts "Placeholder set on #{scope.size} lessons."
  end
end
