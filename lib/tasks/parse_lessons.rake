namespace :lessons do
  desc "Parse a lesson's sections into structured rows using OpenAI. Pass LESSON=10 or LESSON=all"
  task parse: :environment do
    lesson_arg = ENV['LESSON'] || 'all'

    lessons = if lesson_arg == 'all'
      Lesson.ordered
    else
      [ Lesson.find_by!(number: lesson_arg.to_i) ]
    end

    lessons.each do |lesson|
      puts "Parsing lesson #{lesson.number}: #{lesson.title}..."
      parser = LessonSectionParser.new(lesson)
      parser.parse_all
      puts "  Done."
    end
  end

  desc "Show raw text for a lesson without parsing. Pass LESSON=10"
  task inspect: :environment do
    lesson = Lesson.find_by!(number: ENV.fetch('LESSON').to_i)
    %w[grammar texts exercises].each do |section|
      raw = lesson.public_send(section)
      puts "\n=== #{section.upcase} (#{raw&.length || 0} chars) ==="
      puts raw.present? ? raw[0..800] : "(empty)"
    end
  end
end
