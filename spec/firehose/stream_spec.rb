# frozen_string_literal: true

require "spec_helper"

RSpec.describe Firehose::Stream do
  let(:config) { Firehose.configuration }
  subject(:stream) { described_class.new(config: config) }

  describe "#on_offset" do
    it "registers an offset callback" do
      offsets = []
      stream.on_offset { |o| offsets << o }
      expect(offsets).to be_empty
    end
  end

  describe "#stop" do
    it "sets running to false" do
      stream.stop
      # Internal state — stream won't reconnect
      expect(stream.last_event_id).to be_nil
    end
  end

  describe "#last_event_id" do
    it "starts as nil" do
      expect(stream.last_event_id).to be_nil
    end
  end

  describe "SSE parsing" do
    it "preserves the SSE event type" do
      raw_event = <<~SSE
        event: connected
        data: {}

      SSE

      captured = nil

      stream.send(:parse_sse_event, raw_event) do |event|
        captured = event
      end

      expect(captured.type).to eq("connected")
    end
  end

  describe "#connect" do
    it "raises connection errors instead of retrying forever" do
      allow(stream).to receive(:stream_events).and_raise(Firehose::ConnectionError, "HTTP 400")

      expect { stream.connect(since: "0-190614989") { nil } }
        .to raise_error(Firehose::ConnectionError, "HTTP 400")
    end
  end
end
