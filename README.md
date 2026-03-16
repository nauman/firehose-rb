# firehose-rb

Ruby client for the Firehose real-time web monitoring API. SSE streaming with auto-reconnect, rules CRUD, and offset tracking.

## Installation

```ruby
gem "firehose-rb", path: "../firehose-rb"
```

## Configuration

```ruby
Firehose.configure do |c|
  c.management_key = "fhm_..."
  c.tap_token = "fh_..."
  c.base_url = "https://api.firehose.dev"  # default
  c.timeout = 300                           # SSE timeout in seconds
end
```

## Usage

### Rules CRUD

```ruby
client = Firehose.client

# Create a rule
rule = client.create_rule(
  value: '"AI agent" AND language:"en" AND recent:7d',
  tag: "ai-agent",
  quality: true
)

# List rules
rules = client.list_rules

# Delete a rule
client.delete_rule(rule.id)
```

### Streaming

```ruby
client = Firehose.client

# Track offsets for resume
client.on_offset { |offset| save_offset(offset) }

# Stream events (auto-reconnects with exponential backoff)
client.stream(since: "1h") do |event|
  event.id              # String
  event.document.url    # String
  event.document.title  # String
  event.document.markdown # String (full page content)
  event.matched_rule    # String (tag)
  event.matched_at      # Time
end

# Stop streaming
client.stop_stream
```

## Data Structures

- `Firehose::Rule` — id, value, tag, quality, nsfw
- `Firehose::Event` — id, document, matched_rule, matched_at
- `Firehose::Document` — url, title, markdown, categories, types, language, publish_time

## Error Handling

- `Firehose::AuthenticationError` — invalid API keys
- `Firehose::RateLimitError` — rate limited
- `Firehose::ConnectionError` — connection failures
- `Firehose::TimeoutError` — request timeout

SSE streaming auto-reconnects with exponential backoff (1s → 2s → 4s → max 30s).
Authentication errors are not retried.
