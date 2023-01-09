# frozen_string_literal: true

RSpec.describe FaradayMiddleware::AwsSigV4 do
  def faraday(credentials_provider, options = {}, &block)
    options = {
      url: 'https://apigateway.us-east-1.amazonaws.com'
    }.merge(options)

    Faraday.new(options) do |faraday|
      aws_sigv4_options = {
        service: 'apigateway',
        region: 'us-east-1',
        credentials_provider: credentials_provider
      }

      faraday.request :aws_sigv4, aws_sigv4_options
      faraday.response :json, content_type: /\bjson\b/

      faraday.adapter(:test, Faraday::Adapter::Test::Stubs.new, &block)
    end
  end

  let(:response) do
    { 'accountUpdate' =>
      { 'name' => nil,
        'template' => false,
        'templateSkipList' => nil,
        'title' => nil,
        'updateAccountInput' => nil },
      'cloudwatchRoleArn' => nil,
      'self' =>
      { '__type' =>
        'GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/',
        'name' => nil,
        'template' => false,
        'templateSkipList' => nil,
        'title' => nil },
      'throttleSettings' => { 'burstLimit' => 1000, 'rateLimit' => 500.0 } }
  end

  let(:expected_headers) do
    { 'User-Agent' => "Faraday v#{Faraday::VERSION}",
      'host' => 'apigateway.us-east-1.amazonaws.com',
      'x-amz-content-sha256' =>
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' }
  end

  let(:authz_tmpl) do
    'AWS4-HMAC-SHA256 Credential=%<access_key_id>s/20150101/us-east-1/apigateway/aws4_request, ' \
      'SignedHeaders=host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-security-token, ' \
      'Signature=%<signature>s'
  end

  let(:credentials_provider) do
    creds = Aws::InstanceProfileCredentials.new

    allow(creds).to receive(:get_credentials) {
      JSON.dump({
                  'AccessKeyId' => "akid#{Time.now.to_i}",
                  'SecretAccessKey' => "secret#{Time.now.to_i}",
                  'Token' => "token#{Time.now.to_i}",
                  'Expiration' => (Time.now + 3600).xmlschema
                })
    }

    creds
  end

  before do
    stub_const('Net::HTTP::HAVE_ZLIB', true)
  end

  specify do
    account_headers = nil

    client = faraday(credentials_provider) do |stub|
      stub.get('/account') do |env|
        account_headers = env.request_headers
        [200, { 'Content-Type' => 'application/json' }, JSON.dump(response)]
      end
    end

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
      'x-amz-date' => '20150101T000000Z',
      'x-amz-security-token' => 'token1420070400'
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(format(authz_tmpl, access_key_id: 'akid1420070400', signature: "(#{%w[
      61446bb36db613084c87fd0585b649a7aaab25332dd0222f297be130cfdaf9a2
      d162df96dee6beb5f19d114fc5d3373e02d42fcf5b80822747df42f330d76892
      c6cf61acd4fe0a0e70954a392510e6032d4143212c3ab86b210c0640141b7781
      2d26efa112a023b96a72f4e447d11ba199c5e319038d65d8ec718c9a3c16a70f
      5eb8a5c4e55fc4c79831f4a0c64e6982f70ecf92a0b9746b19f31aed70abe805
    ].join('|')})"))

    # 50 minutes after
    Timecop.travel(Time.now + 3000)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
      'x-amz-date' => '20150101T005000Z',
      'x-amz-security-token' => 'token1420070400'
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(format(authz_tmpl, access_key_id: 'akid1420070400', signature: "(#{%w[
      113b39027f338ae11c1ee11673c4ce9bcf25646ee6a412d07f01d3a9dd0cac80
      f0f3939d879bfe26a1e4d3d221d38ed69a76ca715e8d6be00968d162dc20f6f6
      fe734f0838842af459321e8cdb9a1e2df55dd1d38f931e6c7c7b64cf888edf0d
      e63d67d13b49d2268ca3ee14a434b6cd3f674e0c89d02c3c464b724c41680b7a
      ceb35033665fffebd861eec8626128a5a23d603c90d65dc93170c3b893e78121
    ].join('|')})"))

    # 10 minutes after
    Timecop.travel(Time.now + 600)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
      'x-amz-date' => '20150101T010000Z',
      'x-amz-security-token' => 'token1420074000'
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(format(authz_tmpl, access_key_id: 'akid1420074000', signature: "(#{%w[
      c9998f111f32b5f0c665e104a39b910dbc90215d66b6392a1fce9c8ff439af53
      b8db4e5318ef683ff574ad16c16f96866f56d81b5bf591f76aab9537563ab2b2
      146d257eb03c67e6ef74cb56adc4db29c88bb8aa4167d3b39f45c964c36bef7f
      2cdcbb53d0a8db29b59f70e413aab718cc55256382814fd1e5f93f1939370a2c
      71b7e9e9cff745532141cb04b9143a397b52a5f76ff4abe9b456434b32a0ad3d
    ].join('|')})"))
  end
end
