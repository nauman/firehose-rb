# frozen_string_literal: true

require "faraday"
require "json"

module Firehose
  class Client
    def initialize(config: Firehose.configuration)
      @config = config
      @stream = Stream.new(config: config)
    end

    # Tap management (requires management key)

    def list_taps
      response = management_connection.get("/v1/taps")
      handle_response(response)
      parsed = JSON.parse(response.body)
      Array(parsed["data"]).map { |t| Tap.from_hash(t) }
    end

    def create_tap(name:)
      response = management_connection.post("/v1/taps", { name: name }.to_json)
      handle_response(response)
      parsed = JSON.parse(response.body)
      tap_data = parsed["data"] || parsed
      tap_data["token"] = parsed["token"] if parsed["token"]
      Tap.from_hash(tap_data)
    end

    def get_tap(tap_id)
      response = management_connection.get("/v1/taps/#{tap_id}")
      handle_response(response)
      parsed = JSON.parse(response.body)
      Tap.from_hash(parsed["data"] || parsed)
    end

    def update_tap(tap_id, name:)
      response = management_connection.put("/v1/taps/#{tap_id}", { name: name }.to_json)
      handle_response(response)
      parsed = JSON.parse(response.body)
      Tap.from_hash(parsed["data"] || parsed)
    end

    def revoke_tap(tap_id)
      response = management_connection.delete("/v1/taps/#{tap_id}")
      handle_response(response)
      true
    end

    # Rules CRUD (requires tap token)

    def list_rules
      response = tap_connection.get("/v1/rules")
      handle_response(response)
      parsed = JSON.parse(response.body)
      Array(parsed["data"] || parsed).map { |r| Rule.from_hash(r) }
    end

    def create_rule(value:, tag: nil, quality: true, nsfw: false)
      body = { value: value, tag: tag, quality: quality, nsfw: nsfw }.compact
      response = tap_connection.post("/v1/rules", body.to_json)
      handle_response(response)
      parsed = JSON.parse(response.body)
      Rule.from_hash(parsed["data"] || parsed)
    end

    def get_rule(rule_id)
      response = tap_connection.get("/v1/rules/#{rule_id}")
      handle_response(response)
      parsed = JSON.parse(response.body)
      Rule.from_hash(parsed["data"] || parsed)
    end

    def update_rule(rule_id, value: nil, tag: nil, quality: nil, nsfw: nil)
      body = { value: value, tag: tag, quality: quality, nsfw: nsfw }.compact
      response = tap_connection.put("/v1/rules/#{rule_id}", body.to_json)
      handle_response(response)
      parsed = JSON.parse(response.body)
      Rule.from_hash(parsed["data"] || parsed)
    end

    def delete_rule(rule_id)
      response = tap_connection.delete("/v1/rules/#{rule_id}")
      handle_response(response)
      true
    end

    # Streaming (requires tap token)

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

    def tap_connection
      @tap_connection ||= Faraday.new(url: @config.base_url) do |f|
        f.headers["Authorization"] = "Bearer #{@config.tap_token}"
        f.headers["Content-Type"] = "application/json"
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299 then nil
      when 401, 403 then raise AuthenticationError, "Invalid API key"
      when 429 then raise RateLimitError, "Rate limited"
      else raise Error, "HTTP #{response.status}: #{response.body}"
      end
    end
  end
end
