# frozen_string_literal: true

require 'net/http'
require 'ostruct'
require 'timecop'
require 'aws-sdk-core'

if ENV['CI']
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = 'coverage/lcov.info'
  end
  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::LcovFormatter])
  SimpleCov.start unless SimpleCov.running
end

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
