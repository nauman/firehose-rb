# frozen_string_literal: true

require "faraday"
require "json"

module Firehose
  class Client
    def initialize(config: Firehose.configuration)
      @config = config
      @stream = Stream.new(config: config)
    end

    # Rules CRUD

    def create_rule(value:, tag: nil, quality: false, nsfw: false)
      body = { value: value, tag: tag, quality: quality, nsfw: nsfw }.compact
      response = management_connection.post("/rules", body.to_json)
      handle_response(response)
      Rule.from_hash(JSON.parse(response.body))
    end

    def list_rules
      response = management_connection.get("/rules")
      handle_response(response)
      JSON.parse(response.body).map { |r| Rule.from_hash(r) }
    end

    def delete_rule(rule_id)
      response = management_connection.delete("/rules/#{rule_id}")
      handle_response(response)
      true
    end

    # Streaming

    def stream(since: nil, &block)
      raise ArgumentError, "block required" unless block_given?

      @stream.connect(since: since, &block)
    end

    def on_offset(&block)
      @stream.on_offset(&block)
    end

    def stop_stream
      @stream.stop
    end

    private

    def management_connection
      @management_connection ||= Faraday.new(url: @config.base_url) do |f|
        f.headers["Authorization"] = "Bearer #{@config.management_key}"
        f.headers["Content-Type"] = "application/json"
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299 then nil
      when 401, 403 then raise AuthenticationError, "Invalid management key"
      when 429 then raise RateLimitError, "Rate limited"
      else raise Error, "HTTP #{response.status}: #{response.body}"
      end
    end
  end
end
