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

  let(:expected_headers) do
    {"User-Agent"=>"Faraday v#{Faraday::VERSION}",
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
    account__headers = nil

    client = faraday do |stub|
      stub.get('/account') do |env|
        account__headers = env.request_headers
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end

    expect(client.get('/account').body).to eq response

    expect(account__headers).to match(expected_headers.update(
     'x-amz-date' => '20150101T000000Z',
     'x-amz-security-token' => 'token1420070400',
     'authorization' => authz_tmpl % {
        access_key_id: 'akid1420070400',
        signature: '711101701ac9c642f22f99c9d7edf0f92df7885daac11bcce10404bc53e286e3',
      },
    ))

    # 50 minutes after
    Timecop.travel(Time.now + 3000)

    expect(client.get('/account').body).to eq response

    expect(account__headers).to match(expected_headers.update(
     'x-amz-date' => '20150101T005000Z',
     'x-amz-security-token' => 'token1420070400',
     'authorization' => authz_tmpl % {
        access_key_id: 'akid1420070400',
        signature: 'fd6d6245157cc48dc5a185efcaf76a951a4a66bffa27c256a10ec88b883ad005',
      },
    ))

    # 10 minutes after
    Timecop.travel(Time.now + 600)

    expect(client.get('/account').body).to eq response

    expect(account__headers).to match(expected_headers.update(
     'x-amz-date' => '20150101T010000Z',
     'x-amz-security-token' => 'token1420074000',
     'authorization' => authz_tmpl % {
        access_key_id: 'akid1420074000',
        signature: '7f83565a3d7014b34405b39be7e455d9766db5c93403dc1ba6e2ddfb3f9e0011',
      },
    ))
  end
end
