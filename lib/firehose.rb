# frozen_string_literal: true

require_relative "firehose/error"
require_relative "firehose/rule"
require_relative "firehose/tap"
require_relative "firehose/document"
require_relative "firehose/event"
require_relative "firehose/stream"
require_relative "firehose/client"

module Firehose
  class Configuration
    attr_accessor :management_key, :tap_token, :base_url, :timeout

    def initialize
      @base_url = "https://api.firehose.com"
      @timeout = 300
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def client
      Client.new
    end
  end
end
