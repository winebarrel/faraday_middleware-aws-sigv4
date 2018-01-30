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
    {'accountUpdate'=>
      {'name'=>nil,
       'template'=>false,
       'templateSkipList'=>nil,
       'title'=>nil,
       'updateAccountInput'=>nil},
     'cloudwatchRoleArn'=>nil,
     'self'=>
      {'__type'=>
        'GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/',
       'name'=>nil,
       'template'=>false,
       'templateSkipList'=>nil,
       'title'=>nil},
     'throttleSettings'=>{'burstLimit'=>1000, 'rateLimit'=>500.0}}
  end

  let(:signed_headers) do
    'host;user-agent;x-amz-content-sha256;x-amz-date'
  end

  let(:default_expected_headers) do
    {'User-Agent'=>"Faraday v#{Faraday::VERSION}",
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
        expected_headers_without_authorization = expected_headers.dup
        authorization = expected_headers_without_authorization.delete('authorization')
        expect(env.request_headers).to include expected_headers_without_authorization
        expect(env.request_headers.fetch('authorization')).to match Regexp.new(authorization)
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end
  end

  context 'without query' do
    let(:signature) do
      '(' + %w(
        f68c19b5bbb53e2bdd587ed693d20bb90bafb14e31ccd638d9047eb1925fe38f
        bbf43fc1e82754202e2d1233e1ae05f1c19a8f46d2b9e3e14499992104456624
        8318dc891e13d83f5b27a03b87201a7a5cf1d1c02f6f16151908bef57aa5ecab
        b95cea10d840d990f812c44dd1eda5117c0ccd5f06084282e1f39e15e359e641
        5b63c9009fa63ff519f153f8cce8361b478fe9a177d99b17eb96f59b18c910f5
        9a2e392463d9ecfd5e514b181d82d3d271cd9ad9e7ea310ee1590d161882fece
      ).join('|') + ')'
    end

    subject { client.get('/account').body }

    it { is_expected.to eq response }
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        '(' + %w(
          c89da67e4c5cc1e210c7d381a060d047669de524fe3572a1619a9941ae8a4351
          e2e691dae3160861403d8566e028e58c188a3da4475ac365d3af80ea27492d43
          dcea998afac2f7a15e2d901e1ed18b0e0c00411645490156d1adc853c33878ee
          94583a50c8322e121de93e2249e97122316777d848225af91b64a788c879729e
          5ef2b8e952a01523fae861b98687837d7d4b45e7ef5ef423eab037895573d26e
          4b49d892a1b347f85d5f37c2db86a7a90da5c89f1f5dbabe7326375e61b77d1f
        ).join('|') + ')'
      end

      let(:params) { {foo: 'b a r', zoo: 'b a z'} }

      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        '(' + %w(
          b523b730e002c6c1203f5c7806b5c7f9b4120322d5c397255390c366f8593d8b
          04d75864a321030b17f3c0b39259af3a6a0c179507ce2d892abf71ca3286d1df
          19526cfcf8741096b7115813bd8a8928a3f8be6bec35952373213a623fb422a1
          a8e8b24df3c8f6ceb1b5da4707c42fbe003575db960ebe81588b3126d389c42a
          044d89a4b2e0efd313fe3e57dd4594f906a1b54cede3ffb6328d6e1a31c64c8d
          4f91645ce29990646823435ccaefadce2efa9f0db25ca433faf51d4ec94a51e9
        ).join('|') + ')'
      end

      let(:params) { {foo: 'bar', zoo: 'baz'} }

      it { is_expected.to eq response }
    end
  end
end
