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

  def show
    @messages = @chat_session.chat_messages
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
        messages: [{ role: "system", content: system_prompt }] + history,
        temperature: 0.7,
        max_tokens: 512
      }
    )

    assistant_text = response.dig("choices", 0, "message", "content").to_s.strip
    @chat_session.chat_messages.create!(role: "assistant", content: assistant_text)

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
      @chat_session = ChatSession.create!(lesson: @lesson)
      session[session_key] = @chat_session.id
    end
  end

  def system_prompt
    parts = []
    parts << "You are a fluent Mayo Irish (Gaeilge Chonnacht) tutor.\n\n#{tutor_instructions}"
    parts << grammar_context if grammar_context.present?
    parts << vocab_context   if vocab_context.present?
    parts.join("\n\n")
  end

  def tutor_instructions
    @lesson.tutor_prompt.presence || DEFAULT_TUTOR_PROMPT
  end

  def grammar_context
    rules = @lesson.grammar_rules.includes(:grammar_sections)
    return nil if rules.empty?

    lines = ["GRAMMAR RULES:"]
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

    lines = ["VOCABULARY:"]
    items.each do |v|
      gender = v.gender == "m" ? "masc." : "fem."
      parts = ["#{v.irish} (#{gender})"]
      parts << "pl. #{v.plural}" if v.plural.present?
      parts << "— #{v.english}" if v.english.present?
      lines << parts.join(" ")
    end
    lines.join("\n")
  end

  def session_key
    "chat_session_lesson_#{@lesson.id}"
  end
end
