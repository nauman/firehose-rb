# frozen_string_literal: true

require "json"

module Firehose
  Event = Data.define(:id, :type, :document, :matched_rule, :matched_at) do
    def initialize(id:, type: "message", document:, matched_rule: nil, matched_at: nil)
      super
    end

    def self.from_sse(data, id: nil, type: "message")
      parsed = JSON.parse(data)

      doc = Document.from_hash(parsed["document"] || parsed)
      matched_at = parsed["matched_at"] ? Time.parse(parsed["matched_at"]) : nil

      new(
        id: id || parsed["id"],
        type: type,
        document: doc,
        matched_rule: parsed["matched_rule"] || parsed["tag"],
        matched_at: matched_at
      )
    rescue JSON::ParserError => e
      raise Firehose::Error, "Failed to parse SSE event: #{e.message}"
    end
  end
end
