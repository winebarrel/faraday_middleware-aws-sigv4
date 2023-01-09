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
    subject { client.get('/account').body }

    let(:signature) do
      "(#{%w[
        ac7f37878c3680d2c6bc29b42d2461eaa273560870bd96c0b9cb124152bbb511
        cb93fbe9b4ba7fe373c4e31c8dd3447ac0e459b87b8d6715f31be982c7676629
        80fc16ff57e13c9971d12df5edd68aa4c342b070cdfb19c95152802d2a524743
      ].join('|')})"
    end

    it { is_expected.to eq response }
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        "(#{%w[
          1790916eb1f52bd32fd37d4b185132c8d12c9e29edddd80307fbbcb98308e4b9
          a9c40d1e3c7f79841f277b0cf103a4e75c973980e9aff3624462fb2a506c9cc9
          81c2ffe0dcec219164166dca2f950f63a74a634280fb941175b1766e2eabdb17
        ].join('|')})"
      end

      let(:params) { { foo: 'b a r', zoo: 'b a z' } }

      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        "(#{%w[
          94f5de6a367674872b5f63a0bc0328eaefedbce31d80f6005dd5f0daa5e6e7d0
          05bbc8854a20b3df25a0766ad1e06c0f1051065978b7a44d7e16a6f5259e6fee
          16ed3de9531a1c85f1610a23c67d552d368819b48f1937e2a22f36394111d616
        ].join('|')})"
      end

      let(:params) { { foo: 'bar', zoo: 'baz' } }

      it { is_expected.to eq response }
    end
  end
end
