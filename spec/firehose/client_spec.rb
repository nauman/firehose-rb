# frozen_string_literal: true

require "spec_helper"

RSpec.describe Firehose::Client do
  subject(:client) { described_class.new }

  describe "#create_rule" do
    it "creates a rule and returns Rule struct" do
      stub_request(:post, "https://api.firehose.test/rules")
        .with(
          headers: { "Authorization" => "Bearer fhm_test_key" },
          body: { value: '"AI agent"', tag: "ai-agent", quality: true, nsfw: false }.to_json
        )
        .to_return(
          status: 201,
          body: { id: "rule_123", value: '"AI agent"', tag: "ai-agent", quality: true, nsfw: false }.to_json
        )

      rule = client.create_rule(value: '"AI agent"', tag: "ai-agent", quality: true)

      expect(rule).to be_a(Firehose::Rule)
      expect(rule.id).to eq("rule_123")
      expect(rule.tag).to eq("ai-agent")
      expect(rule.quality).to be true
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.firehose.test/rules")
        .to_return(status: 401, body: "Unauthorized")

      expect { client.create_rule(value: "test") }
        .to raise_error(Firehose::AuthenticationError)
    end
  end

  describe "#list_rules" do
    it "returns array of Rule structs" do
      stub_request(:get, "https://api.firehose.test/rules")
        .to_return(
          status: 200,
          body: [
            { id: "r1", value: "test", tag: "t1", quality: false, nsfw: false },
            { id: "r2", value: "test2", tag: "t2", quality: true, nsfw: false }
          ].to_json
        )

      rules = client.list_rules

      expect(rules.length).to eq(2)
      expect(rules.first).to be_a(Firehose::Rule)
      expect(rules.first.id).to eq("r1")
    end
  end

  describe "#delete_rule" do
    it "deletes a rule and returns true" do
      stub_request(:delete, "https://api.firehose.test/rules/rule_123")
        .to_return(status: 204)

      expect(client.delete_rule("rule_123")).to be true
    end

    it "raises RateLimitError on 429" do
      stub_request(:delete, "https://api.firehose.test/rules/rule_123")
        .to_return(status: 429, body: "Rate limited")

      expect { client.delete_rule("rule_123") }
        .to raise_error(Firehose::RateLimitError)
    end
  end

  describe "#stream" do
    it "raises ArgumentError without a block" do
      expect { client.stream }.to raise_error(ArgumentError, "block required")
    end
  end
end
