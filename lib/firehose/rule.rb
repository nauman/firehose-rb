# frozen_string_literal: true

module Firehose
  Rule = Data.define(:id, :value, :tag, :quality, :nsfw) do
    def initialize(id:, value:, tag: nil, quality: false, nsfw: false)
      super
    end

    def self.from_hash(hash)
      new(
        id: hash["id"] || hash[:id],
        value: hash["value"] || hash[:value],
        tag: hash["tag"] || hash[:tag],
        quality: hash["quality"] || hash[:quality] || false,
        nsfw: hash["nsfw"] || hash[:nsfw] || false
      )
    end
  end
end
