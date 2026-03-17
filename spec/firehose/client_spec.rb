# frozen_string_literal: true

require "spec_helper"

RSpec.describe Firehose::Client do
  subject(:client) { described_class.new }

  # Tap management (management key)

  describe "#list_taps" do
    it "returns array of Tap structs" do
      stub_request(:get, "https://api.firehose.test/v1/taps")
        .with(headers: { "Authorization" => "Bearer fhm_test_key" })
        .to_return(
          status: 200,
          body: { data: [
            { id: "tap_1", name: "Brand Mentions", token: "fh_abc", token_prefix: "fh_abc", rules_count: 3 }
          ] }.to_json
        )

      taps = client.list_taps

      expect(taps.length).to eq(1)
      expect(taps.first).to be_a(Firehose::Tap)
      expect(taps.first.name).to eq("Brand Mentions")
      expect(taps.first.token).to eq("fh_abc")
    end
  end

  describe "#create_tap" do
    it "creates a tap and returns Tap struct with token" do
      stub_request(:post, "https://api.firehose.test/v1/taps")
        .with(
          headers: { "Authorization" => "Bearer fhm_test_key" },
          body: { name: "My Tap" }.to_json
        )
        .to_return(
          status: 201,
          body: { data: { id: "tap_2", name: "My Tap", token_prefix: "fh_xyz" }, token: "fh_full_token" }.to_json
        )

      tap = client.create_tap(name: "My Tap")

      expect(tap).to be_a(Firehose::Tap)
      expect(tap.id).to eq("tap_2")
      expect(tap.token).to eq("fh_full_token")
    end
  end

  describe "#get_tap" do
    it "returns a single Tap" do
      stub_request(:get, "https://api.firehose.test/v1/taps/tap_1")
        .to_return(
          status: 200,
          body: { data: { id: "tap_1", name: "Brand Mentions" } }.to_json
        )

      tap = client.get_tap("tap_1")

      expect(tap.id).to eq("tap_1")
      expect(tap.name).to eq("Brand Mentions")
    end
  end

  describe "#update_tap" do
    it "updates tap name" do
      stub_request(:put, "https://api.firehose.test/v1/taps/tap_1")
        .with(body: { name: "New Name" }.to_json)
        .to_return(
          status: 200,
          body: { data: { id: "tap_1", name: "New Name" } }.to_json
        )

      tap = client.update_tap("tap_1", name: "New Name")

      expect(tap.name).to eq("New Name")
    end
  end

  describe "#revoke_tap" do
    it "revokes a tap and returns true" do
      stub_request(:delete, "https://api.firehose.test/v1/taps/tap_1")
        .to_return(status: 204)

      expect(client.revoke_tap("tap_1")).to be true
    end
  end

  # Rules CRUD (tap token)

  describe "#create_rule" do
    it "creates a rule and returns Rule struct" do
      stub_request(:post, "https://api.firehose.test/v1/rules")
        .with(
          headers: { "Authorization" => "Bearer fh_test_token" },
          body: { value: '"AI agent"', tag: "ai-agent", quality: true, nsfw: false }.to_json
        )
        .to_return(
          status: 201,
          body: { data: { id: "rule_123", value: '"AI agent"', tag: "ai-agent", quality: true, nsfw: false } }.to_json
        )

      rule = client.create_rule(value: '"AI agent"', tag: "ai-agent", quality: true)

      expect(rule).to be_a(Firehose::Rule)
      expect(rule.id).to eq("rule_123")
      expect(rule.tag).to eq("ai-agent")
      expect(rule.quality).to be true
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.firehose.test/v1/rules")
        .to_return(status: 401, body: "Unauthorized")

      expect { client.create_rule(value: "test") }
        .to raise_error(Firehose::AuthenticationError)
    end

    it "defaults quality to true" do
      stub_request(:post, "https://api.firehose.test/v1/rules")
        .with(body: { value: "test", quality: true, nsfw: false }.to_json)
        .to_return(
          status: 201,
          body: { data: { id: "r1", value: "test", quality: true } }.to_json
        )

      rule = client.create_rule(value: "test")
      expect(rule.quality).to be true
    end
  end

  describe "#list_rules" do
    it "returns array of Rule structs" do
      stub_request(:get, "https://api.firehose.test/v1/rules")
        .with(headers: { "Authorization" => "Bearer fh_test_token" })
        .to_return(
          status: 200,
          body: { data: [
            { id: "r1", value: "test", tag: "t1" },
            { id: "r2", value: "test2", tag: "t2" }
          ], meta: { count: 2 } }.to_json
        )

      rules = client.list_rules

      expect(rules.length).to eq(2)
      expect(rules.first).to be_a(Firehose::Rule)
      expect(rules.first.id).to eq("r1")
    end
  end

  describe "#get_rule" do
    it "returns a single Rule" do
      stub_request(:get, "https://api.firehose.test/v1/rules/r1")
        .to_return(
          status: 200,
          body: { data: { id: "r1", value: "ahrefs", tag: "brand" } }.to_json
        )

      rule = client.get_rule("r1")

      expect(rule.id).to eq("r1")
      expect(rule.value).to eq("ahrefs")
    end
  end

  describe "#update_rule" do
    it "updates a rule with partial params" do
      stub_request(:put, "https://api.firehose.test/v1/rules/r1")
        .with(body: { tag: "new-tag" }.to_json)
        .to_return(
          status: 200,
          body: { data: { id: "r1", value: "ahrefs", tag: "new-tag" } }.to_json
        )

      rule = client.update_rule("r1", tag: "new-tag")

      expect(rule.tag).to eq("new-tag")
      expect(rule.value).to eq("ahrefs")
    end

    it "updates value and tag together" do
      stub_request(:put, "https://api.firehose.test/v1/rules/r1")
        .with(body: { value: "new query", tag: "updated" }.to_json)
        .to_return(
          status: 200,
          body: { data: { id: "r1", value: "new query", tag: "updated" } }.to_json
        )

      rule = client.update_rule("r1", value: "new query", tag: "updated")

      expect(rule.value).to eq("new query")
    end
  end

  describe "#delete_rule" do
    it "deletes a rule and returns true" do
      stub_request(:delete, "https://api.firehose.test/v1/rules/rule_123")
        .to_return(status: 204)

      expect(client.delete_rule("rule_123")).to be true
    end

    it "raises RateLimitError on 429" do
      stub_request(:delete, "https://api.firehose.test/v1/rules/rule_123")
        .to_return(status: 429, body: "Rate limited")

      expect { client.delete_rule("rule_123") }
        .to raise_error(Firehose::RateLimitError)
    end
  end

  # Streaming

  describe "#stream" do
    it "raises ArgumentError without a block" do
      expect { client.stream }.to raise_error(ArgumentError, "block required")
    end
  end
end
