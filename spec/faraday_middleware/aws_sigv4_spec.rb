# frozen_string_literal: true

RSpec.describe FaradayMiddleware::AwsSigV4 do
  def faraday(options = {}, &block)
    options = {
      url: 'https://apigateway.us-east-1.amazonaws.com'
    }.merge(options)

    Faraday.new(options) do |faraday|
      aws_sigv4_options = {
        service: 'apigateway',
        region: 'us-east-1',
        access_key_id: 'akid',
        secret_access_key: 'secret'
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

  let(:signed_headers) do
    'host;user-agent;x-amz-content-sha256;x-amz-date'
  end

  let(:default_expected_headers) do
    { 'User-Agent' => "Faraday v#{Faraday::VERSION}",
      'host' => 'apigateway.us-east-1.amazonaws.com',
      'x-amz-date' => '20150101T000000Z',
      'x-amz-content-sha256' =>
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      'authorization' =>
      'AWS4-HMAC-SHA256 Credential=akid/20150101/us-east-1/apigateway/aws4_request, ' \
      "SignedHeaders=#{signed_headers}, " \
      "Signature=#{signature}" }
  end

  let(:additional_expected_headers) { {} }

  let(:expected_headers) do
    default_expected_headers.merge(additional_expected_headers)
  end

  let(:client) do
    faraday do |stub|
      stub.get('/account') do |env|
        expected_headers_without_authorization = expected_headers.dup
        authorization = expected_headers_without_authorization.delete('authorization')
        expect(env.request_headers).to include expected_headers_without_authorization
        expect(env.request_headers.fetch('authorization')).to match Regexp.new(authorization)
        [200, { 'Content-Type' => 'application/json' }, JSON.dump(response)]
      end
    end
  end

  context 'without query' do
    let(:signature) do
      "(#{%w[
        619cd780d0eaf2c01fc5afb41f2437f93da2b4a2e0c0cd5997bbc3dfe774c9f5
      ].join('|')})"
    end

    subject { client.get('/account').body }
    it { is_expected.to eq response }
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        "(#{%w[
          95226e86cf00547332b3d74dc05e28836b308da50c228470da745f211721278e
        ].join('|')})"
      end

      let(:params) { { foo: 'b a r', zoo: 'b a z' } }
      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        "(#{%w[
          1b1d9b93b83c50214e3dc582f14587d72706ecf0acab8838cf122fa9dc3e9b62
        ].join('|')})"
      end

      let(:params) { { foo: 'bar', zoo: 'baz' } }
      it { is_expected.to eq response }
    end
  end
end
