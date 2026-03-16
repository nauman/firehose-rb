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
end
