class LessonChatController < ApplicationController
  include SpokenAnswer

  # Each answer, typed or spoken, is a call to the tutor (and a spoken one to ABAIR's recogniser too).
  rate_limit to: 10, within: 1.minute, by: -> { current_user.id }, name: "minute", only: :message,
             with: -> { back_with t("lesson_chat.message.too_fast") }
  rate_limit to: 150, within: 1.day, by: -> { current_user.id }, name: "day", only: :message,
             with: -> { back_with t("lesson_chat.message.daily_limit") }

  before_action :set_lesson
  before_action :set_chat_session

  DEFAULT_TUTOR_PROMPT = <<~PROMPT.freeze
    Based on the grammar rules and vocabulary in this lesson, quiz the student's understanding
    and recall. Use examples from the lesson itself, or similar examples you judge to be
    appropriate. Ask one question at a time. After each answer, briefly explain the relevant
    rule in the context of Mayo Irish (Connacht dialect). Vary your question types — translation,
    recall a rule, identify a form, give an example sentence — whichever is most natural for the
    content at hand.

    Be a forgiving marker. Count an answer as right when it shows the student knows the word or
    rule, even if the spelling, accents, capitals or word order differ a little, or they give
    another form that is also in the lesson. Mayo Irish has forms that differ from the standard
    and from other dialects; never treat a form as wrong only because it is not the standard one.

    Some vocabulary entries are whole sentences or long phrases, often noted down as a speaker
    once said them. Don't ask for those word for word. Ask what they mean, or for a word or
    pattern inside them that is useful on its own, and accept any answer that gets the meaning
    across. Spend most questions on the short words and patterns a learner can build on.
  PROMPT

  LANGUAGE_RULES = <<~RULES.freeze
    LANGUAGE RULES (these override anything above): Write to the student in English.
    Use Irish only when it appears in this lesson's grammar rules or vocabulary below,
    quoted exactly as written there. Never compose, translate or correct Irish sentences
    yourself. If the student needs Irish that is not in the lesson material, say so and
    point them to the lesson text.

    These rules limit what you write, not what the student writes. The student may answer
    in Irish, use the lesson's words in sentences of their own, and use the forms of their
    own dialect. Never tell them to keep to the lesson vocabulary or to answer in English.
    When they write Irish beyond the lesson material, say which lesson words they used
    well. You can't check the rest, so say that once, briefly, without correcting it, and
    mention that "Ask a native speaker" on the lesson page can check it for them.
  RULES

  MASTERY_MARKER_INSTRUCTIONS = <<~INSTRUCTIONS.freeze
    PROGRESS TRACKING: When you are confident the student has demonstrated adequate understanding
    of a topic area, include one of the following markers at the very end of your response (on its
    own line, after your message to the student):
    [MASTERED:vocabulary] — student knows the lesson vocabulary well
    [MASTERED:grammar]    — student has grasped the grammar rules

    Only include a marker when genuinely warranted. You may include multiple markers if several
    areas are mastered. These markers will be hidden from the student.
  INSTRUCTIONS

  def show
    @messages = @chat_session.chat_messages
    @progress = current_user_progress
    @speech = AbairClient.configured?
  end

  # The learner's answer, typed or said aloud. A spoken answer is what ABAIR's recogniser heard.
  def message
    user_text = params[:message].to_s.strip.presence || transcribe(params[:audio])
    return redirect_to lesson_chat_path(@lesson) if user_text.blank?

    @chat_session.chat_messages.create!(role: "user", content: user_text, spoken_seconds: spoken_seconds)

    history = @chat_session.chat_messages.map { |m| { role: m.role, content: m.content } }

    client = OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :openai_key),
      organization_id: Rails.application.credentials.dig(:openai, :openai_org)
    )

    response = client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [ { role: "system", content: system_prompt } ] + history,
        temperature: 0.7,
        max_tokens: 600
      }
    )

    raw_text = response.dig("choices", 0, "message", "content").to_s.strip
    assistant_text, mastered_sections = extract_mastery_markers(raw_text)

    @chat_session.chat_messages.create!(role: "assistant", content: assistant_text)
    record_mastery(mastered_sections)

    redirect_to lesson_chat_path(@lesson)
  rescue RecordingTooLong
    back_with t("lesson_chat.message.too_long")
  rescue NothingHeard
    back_with t("lesson_chat.message.not_heard")
  rescue AbairClient::Error
    back_with t("lesson_chat.message.no_speech_service")
  end

  def clear
    @chat_session.destroy
    session.delete(session_key)
    redirect_to lesson_chat_path(@lesson)
  end

  private

  def back_with(alert)
    redirect_to lesson_chat_path(params[:lesson_id]), alert: alert
  end

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:lesson_id])
  end

  def set_chat_session
    chat_session_id = session[session_key]
    @chat_session = ChatSession.tutor.find_by(id: chat_session_id, lesson: @lesson)

    unless @chat_session
      @chat_session = ChatSession.tutor.create!(lesson: @lesson, user: current_user)
      session[session_key] = @chat_session.id
    end
  end

  def system_prompt
    parts = []
    parts << "You are a fluent Mayo Irish (Gaeilge Chonnacht) tutor.\n\n#{tutor_instructions}"
    parts << LANGUAGE_RULES
    parts << LessonContext.new(@lesson).to_s.presence
    parts << MASTERY_MARKER_INSTRUCTIONS
    parts.compact.join("\n\n")
  end

  def tutor_instructions
    @lesson.tutor_prompt.presence || DEFAULT_TUTOR_PROMPT
  end

  def session_key
    "chat_session_lesson_#{@lesson.id}"
  end

  # Strips [MASTERED:section] markers from the end of the response and returns
  # [clean_text, array_of_mastered_section_names]
  def extract_mastery_markers(text)
    mastered = []
    clean = text.gsub(/\[MASTERED:(#{SectionProgress::SECTION_TYPES.join("|")})\]/i) do
      mastered << Regexp.last_match(1).downcase
      ""
    end.strip
    [ clean, mastered.uniq ]
  end

  def record_mastery(sections)
    return if sections.empty? || current_user.nil?

    sections.each do |section_type|
      SectionProgress.mark_complete(user: current_user, lesson: @lesson, section_type: section_type)
    end
  end

  def current_user_progress
    return {} if current_user.nil?

    current_user.section_progresses
                .where(lesson: @lesson)
                .completed
                .pluck(:section_type)
                .index_with(true)
  end
end
