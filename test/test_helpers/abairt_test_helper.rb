module AbairtTestHelper
  def with_abairt_token(token = "t")
    previous = ENV["ABAIRT_API_TOKEN"]
    ENV["ABAIRT_API_TOKEN"] = token
    yield
  ensure
    ENV["ABAIRT_API_TOKEN"] = previous
  end
end

class ActiveSupport::TestCase
  include AbairtTestHelper
end
