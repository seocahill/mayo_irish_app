# The comhrá: a short conversation in simple Irish about one lesson, with the
# AI playing a Mayo speaker. This is the one place the app lets an AI write
# Irish, so the page labels every reply as AI-generated and lets the learner
# flag it for an editor, and nothing here is ever saved as course material.
#
# Replies come from ABAIR's conversational AI (AbairS2sClient), with OpenAI as
# the fallback when ABAIR fails or gives something unusable. Each reply records
# which one wrote it.
#
#   conversation = LessonConversation.new(chat_session)
#   conversation.reply_to("what the learner said")  # => the reply ChatMessage
#   conversation.reply_to(nil)                      # => an opening line
class LessonConversation
  class Error < StandardError; end

  MODEL = "gpt-4o".freeze
  MAX_INPUT_CHARACTERS = 500
  HISTORY_SIZE = 20

  INSTRUCTIONS = <<~PROMPT.freeze
    You are a friendly native speaker from County Mayo having a spoken conversation in Irish
    with a learner. The learner is working through the lesson below, so talk about its topic
    and keep to its vocabulary and grammar as far as you can.

    - Reply in Irish, in one or two short, simple sentences. Use Mayo (Connacht) forms.
    - Use at least two words from the lesson's VOCABULARY list in every reply.
    - Don't tell the learner that you prefer to speak Irish; just carry on in Irish.
    - End most replies with a simple question, so the conversation keeps going.
    - The learner may type or speak. Speech comes through a recogniser, so expect missing
      accents and odd word breaks, and read it charitably. If the learner writes English
      because they are stuck, still answer in Irish, and use the note to help them.
    - "english": a natural English translation of your reply.
    - "note": one short sentence in English, either correcting a mistake worth mentioning in
      the learner's last message or explaining a word you used, or null when neither is
      needed. Quote Irish words in it only to explain them.
    - If the learner has not said anything yet, open with a greeting and a first simple
      question.

    Respond ONLY with a JSON object with the keys "irish", "english" and "note" (note may be
    null), and no other text.
  PROMPT

  RESPONSE_FORMAT = {
    type: "json_schema",
    json_schema: {
      name: "reply",
      strict: true,
      schema: {
        type: "object",
        additionalProperties: false,
        required: %w[irish english note],
        properties: {
          irish: { type: "string" },
          english: { type: "string" },
          note: { type: %w[string null] }
        }
      }
    }
  }.freeze

  def self.openai_client
    OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :openai_key),
      organization_id: Rails.application.credentials.dig(:openai, :openai_org),
      request_timeout: 30
    )
  end

  def initialize(chat_session, abair: AbairS2sClient.new, openai: self.class.openai_client)
    @chat_session = chat_session
    @abair = abair
    @openai = openai
  end

  # Saves the learner's message and the reply together, only once a usable
  # reply has come back, so a failed call leaves the conversation as it was.
  def reply_to(text)
    said = @chat_session.chat_messages.build(role: "user", content: text.to_s.squish.first(MAX_INPUT_CHARACTERS)) if text.present?
    reply = @chat_session.chat_messages.build(role: "assistant", **ask(said))

    ChatSession.transaction do
      @chat_session.save!
      said&.save!
      reply.save!
    end
    reply
  rescue Error
    @chat_session.chat_messages.reset
    raise
  end

  private

  def ask(said)
    messages = [ { role: "system", content: system_prompt } ] + history(said)
    from_abair(messages) || from_openai(messages)
  end

  def from_abair(messages)
    parse(@abair.reply(messages)).merge(source: "abair")
  rescue AbairS2sClient::Error, Error => e
    Rails.logger.warn("[comhrá] ABAIR gave no usable reply, asking OpenAI: #{e.message}")
    nil
  end

  def from_openai(messages)
    response = @openai.chat(parameters: { model: MODEL, messages: messages, response_format: RESPONSE_FORMAT, temperature: 0.7, max_tokens: 300 })
    parse(response.dig("choices", 0, "message", "content")).merge(source: "openai")
  rescue Faraday::Error => e
    raise Error, "The conversation model could not be reached: #{e.message}"
  end

  def system_prompt
    [ INSTRUCTIONS, LessonContext.new(@chat_session.lesson).brief.presence ].compact.join("\n\n")
  end

  def history(said)
    earlier = @chat_session.chat_messages.select(&:persisted?).last(HISTORY_SIZE)
    (earlier + [ said ].compact).map do |message|
      if message.role == "assistant"
        { role: "assistant", content: { irish: message.content, english: message.english, note: message.note }.to_json }
      else
        { role: "user", content: message.content }
      end
    end
  end

  # ABAIR isn't held to the schema, so take the JSON object out of whatever it says.
  def parse(content)
    reply = JSON.parse(content.to_s[/\{.*\}/m].to_s)
    raise Error, "The conversation model gave no Irish" if reply["irish"].blank?

    { content: reply["irish"].strip, english: reply["english"].presence&.strip, note: reply["note"].presence&.strip }
  rescue JSON::ParserError
    raise Error, "The conversation model's reply wasn't JSON"
  end
end
