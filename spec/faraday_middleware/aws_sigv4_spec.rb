RSpec.describe FaradayMiddleware::AwsSigV4 do
  def faraday(options = {})
    options = {
      url: 'https://apigateway.us-east-1.amazonaws.com'
    }.merge(options)

    Faraday.new(options) do |faraday|
      aws_sigv4_options = {
        service: 'apigateway',
        region: 'us-east-1',
        access_key_id: 'akid',
        secret_access_key: 'secret',
      }

      faraday.request :aws_sigv4, aws_sigv4_options
      faraday.response :json, :content_type => /\bjson\b/

      faraday.adapter(:test, Faraday::Adapter::Test::Stubs.new) do |stub|
        yield(stub)
      end
    end
  end

  let(:response) do
    {"accountUpdate"=>
      {"name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil,
       "updateAccountInput"=>nil},
     "cloudwatchRoleArn"=>nil,
     "self"=>
      {"__type"=>
        "GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/",
       "name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil},
     "throttleSettings"=>{"burstLimit"=>1000, "rateLimit"=>500.0}}
  end

  let(:signed_headers) do
    'host;user-agent;x-amz-content-sha256;x-amz-date'
  end

  let(:default_expected_headers) do
    {"User-Agent"=>"Faraday v#{Faraday::VERSION}",
     'host'=>'apigateway.us-east-1.amazonaws.com',
     'x-amz-date'=>'20150101T000000Z',
     'x-amz-content-sha256'=>
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
     'authorization'=>
      'AWS4-HMAC-SHA256 Credential=akid/20150101/us-east-1/apigateway/aws4_request, ' +
      "SignedHeaders=#{signed_headers}, " +
      "Signature=#{signature}"}
  end

  let(:additional_expected_headers) { {} }

  let(:expected_headers) do
    default_expected_headers.merge(additional_expected_headers)
  end

  let(:client) do
    faraday do |stub|
      stub.get('/account') do |env|
        expect(env.request_headers.sort).to eq expected_headers.sort
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end
  end

  before do
    stub_const('Net::HTTP::HAVE_ZLIB', true)
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        '4b49d892a1b347f85d5f37c2db86a7a90da5c89f1f5dbabe7326375e61b77d1f'
      end

      let(:params) { {foo: 'b a r', zoo: 'b a z'} }

      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        '4f91645ce29990646823435ccaefadce2efa9f0db25ca433faf51d4ec94a51e9'
      end

      let(:params) { {foo: 'bar', zoo: 'baz'} }

      it { is_expected.to eq response }
    end
  end

  context 'use net/http adapter' do
    subject { client.get('/account').body }

    let(:signature) do
      '6a8a8da84ee1dc8ca7ed102efe5db92c58920c858c46d8a9e7fea1d0cace2888'
    end

    let(:signed_headers) do
      'accept;accept-encoding;host;user-agent;x-amz-content-sha256;x-amz-date'
    end

    let(:additional_expected_headers) do
      {"Accept"=>"*/*",
       "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3"}
    end

    before do
      expect_any_instance_of(FaradayMiddleware::AwsSigV4).to receive(:net_http_adapter?).and_return(true)
    end

    it { is_expected.to eq response }
  end
end
