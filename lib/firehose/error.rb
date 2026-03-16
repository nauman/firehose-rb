# frozen_string_literal: true

module Firehose
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class ConnectionError < Error; end
  class TimeoutError < Error; end
end
