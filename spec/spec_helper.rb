# frozen_string_literal: true

require 'net/http'
require 'timecop'
require 'aws-sdk-core'
require 'faraday_middleware/aws_sigv4'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    ENV['TZ'] = 'UTC'
  end

  config.before do
    Timecop.freeze(Time.utc(2015))
  end

  config.after do
    Timecop.return
  end
end
