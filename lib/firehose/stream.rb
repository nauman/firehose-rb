# frozen_string_literal: true

require "net/http"
require "uri"

module Firehose
  class Stream
    MAX_BACKOFF = 30
    INITIAL_BACKOFF = 1

    attr_reader :last_event_id

    def initialize(config:)
      @config = config
      @last_event_id = nil
      @on_offset = nil
      @running = false
    end

    def on_offset(&block)
      @on_offset = block
    end

    def stop
      @running = false
    end

    def connect(since: nil, &block)
      @running = true
      backoff = INITIAL_BACKOFF

      while @running
        begin
          stream_events(since: since, &block)
          backoff = INITIAL_BACKOFF
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT,
               Net::OpenTimeout, Net::ReadTimeout, IOError => e
          break unless @running

          sleep(backoff)
          backoff = [backoff * 2, MAX_BACKOFF].min
          since = nil # use last_event_id on reconnect
        rescue Firehose::AuthenticationError
          raise
        rescue StandardError => e
          break unless @running

          sleep(backoff)
          backoff = [backoff * 2, MAX_BACKOFF].min
          since = nil
        end
      end
    end

    private

    def stream_events(since: nil, &block)
      uri = build_uri(since: since)
      headers = build_headers

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                      open_timeout: 10, read_timeout: @config.timeout) do |http|
        request = Net::HTTP::Get.new(uri, headers)
        buffer = +""

        http.request(request) do |response|
          handle_response_status(response)

          response.read_body do |chunk|
            break unless @running

            buffer << chunk
            process_buffer(buffer, &block)
          end
        end
      end
    end

    def build_uri(since: nil)
      uri = URI.join(@config.base_url, "/v1/stream")
      params = {}
      params["since"] = since if since
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def build_headers
      headers = {
        "Accept" => "text/event-stream",
        "Authorization" => "Bearer #{@config.tap_token}",
        "Cache-Control" => "no-cache"
      }
      headers["Last-Event-ID"] = @last_event_id if @last_event_id
      headers
    end

    def handle_response_status(response)
      case response.code.to_i
      when 200 then nil
      when 401, 403 then raise Firehose::AuthenticationError, "Invalid tap token"
      when 429 then raise Firehose::RateLimitError, "Rate limited"
      else raise Firehose::ConnectionError, "HTTP #{response.code}: #{response.message}"
      end
    end

    def process_buffer(buffer, &block)
      while (idx = buffer.index("\n\n"))
        raw_event = buffer.slice!(0, idx + 2)
        parse_sse_event(raw_event, &block)
      end
    end

    def parse_sse_event(raw, &block)
      id = nil
      data_lines = []

      raw.each_line do |line|
        line = line.chomp
        if line.start_with?("id:")
          id = line.sub("id:", "").strip
        elsif line.start_with?("data:")
          data_lines << line.sub("data:", "").strip
        end
      end

      return if data_lines.empty?

      data = data_lines.join("\n")
      event = Event.from_sse(data, id: id)

      @last_event_id = id if id
      @on_offset&.call(@last_event_id)

      block.call(event)
    end
  end
end
