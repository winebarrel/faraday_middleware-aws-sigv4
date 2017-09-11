require 'faraday'

module FaradayMiddleware
  autoload :AwsSigV4, 'faraday_middleware/request/aws_sigv4'
  Faraday::Request.register_middleware aws_sigv4: lambda { AwsSigV4 }
end
