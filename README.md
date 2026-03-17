# firehose-rb

[![Gem Version](https://badge.fury.io/rb/firehose-rb.svg)](https://rubygems.org/gems/firehose-rb)

Ruby client for the [Firehose](https://firehose.dev) real-time web monitoring API. Define rules, stream matching pages as they're discovered, and build content pipelines on top of the live web.

## Installation

```ruby
gem "firehose-rb", "~> 0.1"
```

Then `bundle install`.

## Configuration

```ruby
Firehose.configure do |c|
  c.management_key = ENV["FIREHOSE_MANAGEMENT_KEY"]  # fhm_...
  c.tap_token      = ENV["FIREHOSE_TAP_TOKEN"]       # fh_...
  c.base_url       = "https://api.firehose.dev"      # default
  c.timeout        = 300                              # SSE timeout in seconds
end
```

## Usage

### Rules

Rules tell Firehose what to watch for. They use Lucene query syntax.

```ruby
client = Firehose.client

# Create a rule
rule = client.create_rule(
  value: '"AI agent" AND language:"en" AND recent:7d',
  tag: "ai-agent",
  quality: true
)

# List all rules
rules = client.list_rules

# Delete a rule
client.delete_rule(rule.id)
```

### Streaming

Connect to the SSE stream and process matching pages in real time.

```ruby
client = Firehose.client

# Persist offsets so you can resume after restart
client.on_offset { |offset| save_offset(offset) }

# Stream events (auto-reconnects with exponential backoff)
client.stream(since: "1h") do |event|
  event.id                    # String — unique event ID
  event.document.url          # String — page URL
  event.document.title        # String — page title
  event.document.markdown     # String — full page content as markdown
  event.document.categories   # Array  — page categories
  event.document.types        # Array  — page types (article, blog, etc.)
  event.document.language     # String — detected language
  event.document.publish_time # Time   — when the page was published
  event.matched_rule          # String — which rule tag matched
  event.matched_at            # Time   — when the match occurred
end

# Stop streaming gracefully
client.stop_stream
```

### Resilience

- Auto-reconnect with exponential backoff (1s, 2s, 4s, ... max 30s)
- `Last-Event-ID` header sent on reconnect for automatic resume
- `on_offset` callback for persisting stream position
- Authentication errors (`401/403`) are not retried

## Data Structures

| Struct | Fields |
|--------|--------|
| `Firehose::Rule` | id, value, tag, quality, nsfw |
| `Firehose::Event` | id, document, matched_rule, matched_at |
| `Firehose::Document` | url, title, markdown, categories, types, language, publish_time |

## Errors

| Error | Cause |
|-------|-------|
| `Firehose::AuthenticationError` | Invalid management_key or tap_token |
| `Firehose::RateLimitError` | Too many requests (429) |
| `Firehose::ConnectionError` | Network or HTTP errors |
| `Firehose::TimeoutError` | Stream or request timeout |

## Requirements

- Ruby >= 3.1
- [Faraday](https://github.com/lostisland/faraday) ~> 2.0

## Used by

Built for [InventList](https://inventlist.com) — a home for indie builders that turns the live web into weekly signals for makers and their agents.

## License

MIT
