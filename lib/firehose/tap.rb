# frozen_string_literal: true

module Firehose
  Tap = Data.define(:id, :name, :token, :token_prefix, :rules_count, :last_used_at, :created_at) do
    def initialize(id:, name:, token: nil, token_prefix: nil, rules_count: 0, last_used_at: nil, created_at: nil)
      super
    end

    def self.from_hash(hash)
      new(
        id: hash["id"] || hash[:id],
        name: hash["name"] || hash[:name],
        token: hash["token"] || hash[:token],
        token_prefix: hash["token_prefix"] || hash[:token_prefix],
        rules_count: hash["rules_count"] || hash[:rules_count] || 0,
        last_used_at: hash["last_used_at"] || hash[:last_used_at],
        created_at: hash["created_at"] || hash[:created_at]
      )
    end
  end
end
