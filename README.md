# FaradayMiddleware::AwsSigV4

[Faraday](https://github.com/lostisland/faraday) middleware for AWS Signature Version 4 using [aws-sigv4](https://rubygems.org/gems/aws-sigv4).

[![Gem Version](https://badge.fury.io/rb/faraday_middleware-aws-sigv4.svg)](https://badge.fury.io/rb/faraday_middleware-aws-sigv4)
[![Build Status](https://travis-ci.org/winebarrel/faraday_middleware-aws-sigv4.svg?branch=master)](https://travis-ci.org/winebarrel/faraday_middleware-aws-sigv4)
[![Coverage Status](https://coveralls.io/repos/github/winebarrel/faraday_middleware-aws-sigv4/badge.svg?branch=master)](https://coveralls.io/github/winebarrel/faraday_middleware-aws-sigv4?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday_middleware-aws-sigv4'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday_middleware-aws-sigv4

## Usage

```ruby
# `gem install faraday_middleware` is required.
require 'faraday_middleware'
require 'faraday_middleware/aws_sigv4'
require 'pp'

conn = Faraday.new(url: 'https://apigateway.us-east-1.amazonaws.com') do |faraday|
  faraday.request :aws_sigv4,
    service: 'apigateway',
    region: 'us-east-1',
    access_key_id: ENV['AWS_ACCESS_KEY_ID'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  # see http://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Sigv4/Signer.html

  faraday.response :json, content_type: /\bjson\b/
  faraday.response :raise_error

  faraday.adapter Faraday.default_adapter
end

res = conn.get '/account'

pp res.body
#=> {"_links"=>
#     {"curies"=>
#       {"href"=>
#         "http://docs.aws.amazon.com/apigateway/latest/developerguide/account-apigateway-{rel}.html",
#        "name"=>"account",
#        "templated"=>true},
#      "self"=>{"href"=>"/account"},
#      "account:update"=>{"href"=>"/account"}},
#    "throttleSettings"=>{"rateLimit"=>10000.0, "burstLimit"=>5000}}
```

## Upgrading from `faraday_middleware-aws-signers-v4`

If you previously provided the `service_name` option, you need to rename it `service`

## Related Links

* http://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Sigv4/Signer.html
* https://github.com/winebarrel/faraday_middleware-aws-signers-v4 (aws-sdk-v2 version)
