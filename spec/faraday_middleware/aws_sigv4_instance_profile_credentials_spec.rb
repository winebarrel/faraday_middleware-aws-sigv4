RSpec.describe FaradayMiddleware::AwsSigV4 do
  def faraday(options = {})
    options = {
      url: 'https://apigateway.us-east-1.amazonaws.com'
    }.merge(options)

    Faraday.new(options) do |faraday|
      aws_sigv4_options = {
        service: 'apigateway',
        region: 'us-east-1',
        credentials_provider: Aws::InstanceProfileCredentials.new,
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

  let(:expected_headers) do
    {'User-Agent'=>"Faraday v#{Faraday::VERSION}",
     'host'=>'apigateway.us-east-1.amazonaws.com',
     'x-amz-content-sha256'=>
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'}
  end

  let(:authz_tmpl) do
    'AWS4-HMAC-SHA256 Credential=%{access_key_id}/20150101/us-east-1/apigateway/aws4_request, ' +
    "SignedHeaders=host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-security-token, " +
    "Signature=%{signature}"
  end

  before do
    stub_const('Net::HTTP::HAVE_ZLIB', true)

    allow_any_instance_of(Aws::InstanceProfileCredentials).to receive(:get_credentials) {
      JSON.dump({
        'AccessKeyId' => "akid#{Time.now.to_i}",
        'SecretAccessKey' => "secret#{Time.now.to_i}",
        'Token' => "token#{Time.now.to_i}",
        'Expiration' => Time.now + 3600,
      })
    }
  end

  specify do
    account_headers = nil

    client = faraday do |stub|
      stub.get('/account') do |env|
        account_headers = env.request_headers
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
     'x-amz-date' => '20150101T000000Z',
     'x-amz-security-token' => 'token1420070400',
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(
      authz_tmpl % {
        access_key_id: 'akid1420070400',
        signature: '(' + %w(
          df222e9a8c7a0733ccf3a97b28189862c869dbbe6d1c7d2cb502e3d220b71744
          dc305e6e5022f6708fec934bf8087d5079460f4aad78b9c7f16de2c474ebfab0
          b610edfeeebb18d291fb4955b1dba775892d24cef182df3ab72c1581db326036
          b12220aa247ee1dd3f175d7a6416b3888e1f1c60e418180d25cba120a4a41a91
          711101701ac9c642f22f99c9d7edf0f92df7885daac11bcce10404bc53e286e3
          64c9cc9b5905ebf9d2e5531a5cc5df13f6c1e3154b0d98aa7b9efd2030f7adef
        ).join('|') + ')',
      }
    )

    # 50 minutes after
    Timecop.travel(Time.now + 3000)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
     'x-amz-date' => '20150101T005000Z',
     'x-amz-security-token' => 'token1420070400',
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(
      authz_tmpl % {
        access_key_id: 'akid1420070400',
        signature: '(' + %w(
          88c960305eace329590928d9d947a1c75323cade79b5b6c3484ff81f8eba4205
          2d69679e39b670c5a76faa7b3bcb3cc7dbdf9ef2b0d0cb3ca997aedf0578794a
          e2ae9ad9df78b0876b97f018087d892ac8095dd865e74878f70023eac5ed574d
          63ef067e40708d4cdfcf71742cf6b5ebc782decf099d6f63d4a0855f14d247d1
          fd6d6245157cc48dc5a185efcaf76a951a4a66bffa27c256a10ec88b883ad005
          4c43da23f63ca6961b8919dd77519a15a9d332ff0cd171b5cb8e2574850bd7d1
        ).join('|') + ')',
      }
    )

    # 10 minutes after
    Timecop.travel(Time.now + 600)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
     'x-amz-date' => '20150101T010000Z',
     'x-amz-security-token' => 'token1420074000',
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(
      authz_tmpl % {
        access_key_id: 'akid1420074000',
        signature: '(' + %w(
          506eb7dbe293c53aaf652070ff32339fd2ef5ca785bd36886e4485d78f283a42
          3256eddafd3eb847e2314e4ac26056089927330b3076aa1bfc310bd0e7e9ce02
          e2c60bbf98273197f8e54cbcad61a53b35a1e6db10cd184b9e18c7030d2438b0
          e20185cc24bf99ababe02bbad0e9a15d412ccb7f88aa92300d596194637447ab
          7f83565a3d7014b34405b39be7e455d9766db5c93403dc1ba6e2ddfb3f9e0011
          986f14736987ff8781706ed10d55b9bab635a56824d8237feaf6fa582bd4b368
        ).join('|') + ')',
      }
    )
  end
end
