# frozen_string_literal: true

require "spec_helper"

RSpec.describe Firehose::Event do
  describe ".from_sse" do
    let(:sse_data) do
      {
        id: "evt_123",
        document: {
          url: "https://example.com/article",
          title: "AI Agents Are Here",
          markdown: "# AI Agents\n\nFull article content...",
          categories: ["technology", "ai"],
          types: ["article"],
          language: "en",
          publish_time: "2026-03-16T10:00:00Z"
        },
        matched_rule: "ai-agent",
        matched_at: "2026-03-16T10:05:00Z"
      }.to_json
    end

    it "parses SSE data into Event with Document" do
      event = described_class.from_sse(sse_data)

      expect(event).to be_a(Firehose::Event)
      expect(event.document).to be_a(Firehose::Document)
      expect(event.document.url).to eq("https://example.com/article")
      expect(event.document.title).to eq("AI Agents Are Here")
      expect(event.document.categories).to eq(["technology", "ai"])
      expect(event.matched_rule).to eq("ai-agent")
    end

    it "uses explicit id when provided" do
      event = described_class.from_sse(sse_data, id: "custom_id")

      expect(event.id).to eq("custom_id")
    end

    it "raises on invalid JSON" do
      expect { described_class.from_sse("not json") }
        .to raise_error(Firehose::Error, /Failed to parse/)
    end
  end
end
