# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "firehose-rb"
  spec.version       = "0.1.0"
  spec.authors       = ["Nauman Tariq"]
  spec.email         = ["nauman@intellecta.co"]
  spec.summary       = "Ruby client for the Firehose real-time web monitoring API"
  spec.description   = "SSE streaming client with rules CRUD, auto-reconnect, and offset tracking for the Firehose API."
  spec.homepage      = "https://github.com/naumantariq/firehose-rb"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
end
