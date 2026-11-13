# The OpenAI client, built from the app's credentials.
#
#   OpenaiClient.build.chat(parameters: { … })
module OpenaiClient
  def self.build(request_timeout: 30)
    OpenAI::Client.new(
      access_token: Rails.application.credentials.dig(:openai, :openai_key),
      organization_id: Rails.application.credentials.dig(:openai, :openai_org),
      request_timeout: request_timeout
    )
  end
end
