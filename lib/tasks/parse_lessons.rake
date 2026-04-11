namespace :lessons do
  desc "Parse a lesson's OCR text into structured DB records using OpenAI. Pass LESSON=10 or LESSON=all"
  task parse: :environment do
    lesson_arg = ENV['LESSON'] || 'all'

    lessons = if lesson_arg == 'all'
      Lesson.ordered
    else
      [ Lesson.find_by!(number: lesson_arg.to_i) ]
    end

    lessons.each do |lesson|
      puts "Parsing lesson #{lesson.number}: #{lesson.title}..."
      LessonStructureParser.new(lesson).parse
      puts "  Done."
    end
  end

  desc "Show raw OCR text for a lesson. Pass LESSON=10"
  task inspect: :environment do
    lesson = Lesson.find_by!(number: ENV.fetch('LESSON').to_i)
    %w[grammar texts exercises vocabulary_notes].each do |field|
      raw = lesson.public_send(field)
      puts "\n=== #{field.upcase} (#{raw&.length || 0} chars) ==="
      puts raw.present? ? raw[0..600] : "(empty)"
    end
  end
end
