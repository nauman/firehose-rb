# frozen_string_literal: true

module Firehose
  Document = Data.define(:url, :title, :markdown, :categories, :types, :language, :publish_time) do
    def initialize(url:, title: nil, markdown: nil, categories: [], types: [], language: nil, publish_time: nil)
      super
    end

    def self.from_hash(hash)
      new(
        url: hash["url"] || hash[:url],
        title: hash["title"] || hash[:title],
        markdown: hash["markdown"] || hash[:markdown],
        categories: Array(hash["categories"] || hash[:categories]),
        types: Array(hash["types"] || hash[:types]),
        language: hash["language"] || hash[:language],
        publish_time: parse_time(hash["publish_time"] || hash[:publish_time])
      )
    end

    def self.parse_time(value)
      return nil if value.nil?
      return value if value.is_a?(Time)

      Time.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
