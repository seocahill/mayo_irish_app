class LessonChatController < ApplicationController
  before_action :set_lesson
  before_action :set_chat_session

  DEFAULT_TUTOR_PROMPT = <<~PROMPT.freeze
    Based on the grammar rules and vocabulary in this lesson, quiz the student's understanding
    and recall. Use examples from the lesson itself, or similar examples you judge to be
    appropriate. Ask one question at a time. After each answer, briefly explain the relevant
    rule in the context of Mayo Irish (Connacht dialect). Vary your question types — translation,
    recall a rule, identify a form, give an example sentence — whichever is most natural for the
    content at hand.
  PROMPT

  LANGUAGE_RULES = <<~RULES.freeze
    LANGUAGE RULES (these override anything above): Write to the student in English.
    Use Irish only when it appears in this lesson's grammar rules or vocabulary below,
    quoted exactly as written there. Never compose, translate or correct Irish sentences
    yourself. If the student needs Irish that is not in the lesson material, say so and
    point them to the lesson text.
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
  end

  def message
    user_text = params[:message].to_s.strip
    return redirect_to lesson_chat_path(@lesson) if user_text.blank?

    @chat_session.chat_messages.create!(role: "user", content: user_text)

    history = @chat_session.chat_messages.map { |m| { role: m.role, content: m.content } }

    client = OpenAI::Client.new(
      access_token: Rails.application.credentials.openai.openai_key,
      organization_id: Rails.application.credentials.openai.openai_org
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
  end

  def clear
    @chat_session.destroy
    session.delete(session_key)
    redirect_to lesson_chat_path(@lesson)
  end

  private

  def set_lesson
    @lesson = Lesson.find_by!(number: params[:lesson_id])
  end

  def set_chat_session
    chat_session_id = session[session_key]
    @chat_session = ChatSession.find_by(id: chat_session_id, lesson: @lesson)

    unless @chat_session
      @chat_session = ChatSession.create!(lesson: @lesson, user: current_user)
      session[session_key] = @chat_session.id
    end
  end

  def system_prompt
    parts = []
    parts << "You are a fluent Mayo Irish (Gaeilge Chonnacht) tutor.\n\n#{tutor_instructions}"
    parts << LANGUAGE_RULES
    parts << grammar_context if grammar_context.present?
    parts << vocab_context   if vocab_context.present?
    parts << MASTERY_MARKER_INSTRUCTIONS
    parts.join("\n\n")
  end

  def tutor_instructions
    @lesson.tutor_prompt.presence || DEFAULT_TUTOR_PROMPT
  end

  def grammar_context
    rules = @lesson.grammar_rules.includes(:grammar_sections)
    return nil if rules.empty?

    lines = [ "GRAMMAR RULES:" ]
    rules.each do |rule|
      lines << "\n#{rule.number}. #{rule.title}"
      lines << rule.body.to_plain_text.strip if rule.body.present?
      rule.grammar_sections.each do |section|
        lines << "  #{section.label}:" if section.label.present?
        lines << "  #{section.body.to_plain_text.strip}" if section.body.present?
      end
    end
    lines.join("\n")
  end

  def vocab_context
    items = @lesson.vocabulary_items
    return nil if items.empty?

    lines = [ "VOCABULARY:" ]
    items.each do |v|
      gender = v.gender == "m" ? "masc." : "fem."
      parts = [ "#{v.irish} (#{gender})" ]
      parts << "pl. #{v.plural}" if v.plural.present?
      parts << "— #{v.english}" if v.english.present?
      lines << parts.join(" ")
    end
    lines.join("\n")
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
