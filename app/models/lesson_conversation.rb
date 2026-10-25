# The comhrá: a short conversation in simple Irish about one lesson, with the
# AI playing a Mayo speaker. This is the one place the app lets an AI write
# Irish, so the page labels every reply as AI-generated and lets the learner
# flag it for an editor, and nothing here is ever saved as course material.
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

  def self.client
    OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :openai_key),
      organization_id: Rails.application.credentials.dig(:openai, :openai_org),
      request_timeout: 30
    )
  end

  def initialize(chat_session, client: self.class.client)
    @chat_session = chat_session
    @client = client
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
    response = @client.chat(parameters: {
      model: MODEL,
      messages: [ { role: "system", content: system_prompt } ] + history(said),
      response_format: RESPONSE_FORMAT,
      temperature: 0.7,
      max_tokens: 300
    })
    parse(response.dig("choices", 0, "message", "content"))
  rescue Faraday::Error => e
    raise Error, "The conversation model could not be reached: #{e.message}"
  end

  def system_prompt
    [ INSTRUCTIONS, LessonContext.new(@chat_session.lesson).to_s.presence ].compact.join("\n\n")
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

  def parse(content)
    reply = JSON.parse(content.to_s)
    raise Error, "The conversation model gave no Irish" if reply["irish"].blank?

    { content: reply["irish"].strip, english: reply["english"].presence&.strip, note: reply["note"].presence&.strip }
  rescue JSON::ParserError
    raise Error, "The conversation model's reply wasn't JSON"
  end
end
