# frozen_string_literal: true

require 'open3'
require 'rbconfig'

RSpec.describe FaradayMiddleware::AwsSigV4 do
  # Run in a separate process because spec_helper has already loaded the gem
  def run_ruby(script)
    lib_dir = File.expand_path('../../lib', __dir__)
    Open3.capture2e(RbConfig.ruby, '-I', lib_dir, '-e', script)
  end

  describe 'entrypoints' do
    it 'is loaded by the path Bundler.require derives from the gem name' do
      # Bundler.require retries with dashes replaced by slashes
      expect('faraday_middleware-aws-sigv4'.tr('-', '/')).to eq 'faraday_middleware/aws/sigv4'

      out, status = run_ruby(<<~RUBY)
        require 'faraday_middleware/aws/sigv4'
        p defined?(FaradayMiddleware::AwsSigV4)
        p Faraday::Request.lookup_middleware(:aws_sigv4)
      RUBY

      expect(status).to be_success, out
      expect(out).to eq %("constant"\nFaradayMiddleware::AwsSigV4\n)
    end

    it 'loads the code only once when both paths are required' do
      out, status = run_ruby(<<~RUBY)
        require 'faraday_middleware/aws_sigv4'
        require 'faraday_middleware/aws/sigv4'
        p $LOADED_FEATURES.count { |f| f.end_with?('/faraday_middleware/aws_sigv4.rb') }
      RUBY

      expect(status).to be_success, out
      expect(out).to eq "1\n"
    end
  end
end
