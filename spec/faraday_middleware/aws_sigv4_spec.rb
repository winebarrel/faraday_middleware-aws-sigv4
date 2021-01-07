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
        4029fcbe5aae50c588651d5a587f4a9fd2b7ba25bc03e1ce57432c758d1a7816
        024535e1dd5a9f9eb5a8d2eb99c64678766ad6059bdd51ad85d282f49bd20700
        f15f7c05bba9addb232e39282ea70a7a7c7f2c52dffd4aafe6cc8226fb82d5ab
        f4299dc8cdf28ee680bb882712daf8fac89c1bcfd46f28549bd37b9412d18b72
        afb745a953d7e80be81d81ed5425a0a7340cea4d8baf42470bd2c0cda14e5103
        300f2ca52b5520e67a39900a0850b8691710382a124c14de6f5d741bcf136704
        daa64ff3387cfee9b4676cf540d5db1093c117df7e24a37ff9badc7ffcc95ede
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
          75bb1b4dbbf7b7a502ecb574abfcc2e12ce115da07f876d3b66fd3ff0ad427fd
          f0a9030e2e15012d61af8b708ad358c9a5e5495984162884abf1cb910275223b
          b13ce117f8258ebc4c157b1d216517f38476d80d6a60ace9374d0ec8d500134d
          53df7eeeaec828ce3c8ca011ee35f20ab620fe1d8610ff00e6a57cab642d2436
          51e82ebaf936d6dc7a673723240a954b35ac5992e7da3408e25d14715fe24aca
          ba63e75f4a2635130bfa2484595227b1244c41638713906b470f5ea0e215cb8a
          bb4a14dc499ed57c9951e39e790c1e622cb15fd6bd1545335893cf9f8209a8d1
        ].join('|')})"
      end

      let(:params) { { foo: 'b a r', zoo: 'b a z' } }
      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        "(#{%w[
          94e01cc599b3eef64cc9e08c5f079b0345d5b9dd95cc14d0ea66fc0c5923bf30
          8c58f5f0decfb7f185d290bae83dac382328ba19c862861fd646089ba0083569
          115cea2f319d5cf12bd4fa35b8861eaded8037dad4ccc7e8c8929d150ddf3d66
          552a531f290603c378a4d01a2a307ba4b356c7e7364ac03b337e80085733b61e
          3d61f6bd2c027925d3da79c87a69b5b77b595687a5c06576c2d8ff66db459415
          405004d0ffaa9ba489a1eec3760e08f790f8a066ff1334c243e28a271026c773
          c2802366b46fbf4d832f8917484c93d0cb4b4cc1f7512f3745a42cd9b13da78b
        ].join('|')})"
      end

      let(:params) { { foo: 'bar', zoo: 'baz' } }
      it { is_expected.to eq response }
    end
  end
end
