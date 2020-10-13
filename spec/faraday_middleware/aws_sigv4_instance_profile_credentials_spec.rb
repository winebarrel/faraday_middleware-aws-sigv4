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

    expect(account_headers.fetch('authorization')).to match Regexp.new(authz_tmpl % {
      access_key_id: 'akid1420070400',
      signature: '(' + %w(
        8a7679e7f6e14faa3c5bc8e585f16416bba04883767b651169f745e987908c04
        0593f7578c038c94d3d463d5b1ed0fa8b4c4f5525c7abb08ae6c095d9df5fb61
        bb9d431b7be57abce9d81b4b4fd62036eec4d9d4e9dc44ad95b1166a8b16c3f4
      ).join('|') + ')',
    })

    # 50 minutes after
    Timecop.travel(Time.now + 3000)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
     'x-amz-date' => '20150101T005000Z',
     'x-amz-security-token' => 'token1420070400',
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(authz_tmpl % {
      access_key_id: 'akid1420070400',
      signature: '(' + %w(
        936d7c18c31135cb0baebe62ada628644a4c24efcadce044ceb650bc04e3fe1d
        891f865c1a1297ed133589cd2abb575fd998b66cf79a0505941f50ef3405576b
        816c7f811b60426fb2cd232ae3a5c6568f5150058bdaa99e3233b61fe8ab7668
      ).join('|') + ')',
    })

    # 10 minutes after
    Timecop.travel(Time.now + 600)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
     'x-amz-date' => '20150101T010000Z',
     'x-amz-security-token' => 'token1420074000',
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(authz_tmpl % {
      access_key_id: 'akid1420074000',
      signature: '(' + %w(
        42b4050c22d246f66c13357186a87bb2891ea0bebf7663cec398f9a12d869133
        f264df5cb2359d8b9d491ff48bd57237d9260f01ebf638455ca18c3dab8beb2d
        7e8b319cb3ab3d36bd4a6b34d411c03f88891d2266adcc9498573c4ee33d2088
      ).join('|') + ')',
    })
  end
end
