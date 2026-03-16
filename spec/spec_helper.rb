# frozen_string_literal: true

require "firehose"
require "webmock/rspec"

RSpec.configure do |config|
  config.before(:each) do
    Firehose.configure do |c|
      c.management_key = "fhm_test_key"
      c.tap_token = "fh_test_token"
      c.base_url = "https://api.firehose.test"
    end
  end

  config.after(:each) do
    Firehose.reset_configuration!
  end
end
