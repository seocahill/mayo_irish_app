module LessonsHelper
  # Rich text with its Irish marked for reading aloud (see SpeakableIrish),
  # when there's a voice to read it.
  def speakable_irish(rich_text)
    return rich_text unless AbairClient.configured?

    @course_language ||= CourseLanguage.current
    SpeakableIrish.new(rich_text.to_s, language: @course_language).to_html.html_safe
  end
end
