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
        credentials_provider: Aws::InstanceProfileCredentials.new
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

  before do
    stub_const('Net::HTTP::HAVE_ZLIB', true)

    allow_any_instance_of(Aws::InstanceProfileCredentials).to receive(:get_credentials) {
      JSON.dump({
                  'AccessKeyId' => "akid#{Time.now.to_i}",
                  'SecretAccessKey' => "secret#{Time.now.to_i}",
                  'Token' => "token#{Time.now.to_i}",
                  'Expiration' => Time.now + 3600
                })
    }
  end

  specify do
    account_headers = nil

    client = faraday do |stub|
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
      8a7679e7f6e14faa3c5bc8e585f16416bba04883767b651169f745e987908c04
      0593f7578c038c94d3d463d5b1ed0fa8b4c4f5525c7abb08ae6c095d9df5fb61
      bb9d431b7be57abce9d81b4b4fd62036eec4d9d4e9dc44ad95b1166a8b16c3f4
      3dd176d303ac2227e8522eb13413670657821280569556d289047e6ae2ccd975
      14af79b17c4e94c9582512125daa97f19b19b04d0b8d605d68a02bded3948770
      05ffc543834d0e93920a4abc60d63f3855b829260877b9c350822eff129e60f9
      ef99e44bec3dc9abfad2c4cfa0203c7d80e979c840038ca6d700cec5b0c85ebe
    ].join('|')})"))

    # 50 minutes after
    Timecop.travel(Time.now + 3000)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
      'x-amz-date' => '20150101T005000Z',
      'x-amz-security-token' => 'token1420070400'
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(format(authz_tmpl, access_key_id: 'akid1420070400', signature: "(#{%w[
      936d7c18c31135cb0baebe62ada628644a4c24efcadce044ceb650bc04e3fe1d
      891f865c1a1297ed133589cd2abb575fd998b66cf79a0505941f50ef3405576b
      816c7f811b60426fb2cd232ae3a5c6568f5150058bdaa99e3233b61fe8ab7668
      053ed3702ade746b97a3aeba3f4bfdd06154b0c7d0cc50fa9ba3db81385f6110
      8ac6851c02183ca987e91116262c9afe24662aff4a7f2dcb67b8d9212cd2d4ba
      a86dcfb7ddc4a60477601814aa3a17e24d278ba0d58844f5c9188b9ce630837d
      6dbd5c1d235a959f7191ec12493eb020213e04c1318d33ed3b4808cbe396867e
    ].join('|')})"))

    # 10 minutes after
    Timecop.travel(Time.now + 600)

    expect(client.get('/account').body).to eq response

    expect(account_headers).to include expected_headers.update(
      'x-amz-date' => '20150101T010000Z',
      'x-amz-security-token' => 'token1420074000'
    )

    expect(account_headers.fetch('authorization')).to match Regexp.new(format(authz_tmpl, access_key_id: 'akid1420074000', signature: "(#{%w[
      42b4050c22d246f66c13357186a87bb2891ea0bebf7663cec398f9a12d869133
      f264df5cb2359d8b9d491ff48bd57237d9260f01ebf638455ca18c3dab8beb2d
      7e8b319cb3ab3d36bd4a6b34d411c03f88891d2266adcc9498573c4ee33d2088
      dca2842cb07926a4929af3708165ca2897207ca729cab19c1deb518d5d492848
      c17ee288dfc7e4598e333765b85e0305959ba33835453b7c2885b7d43aabb4f2
      ae6e1e133d0b033b29ec7050c43ebf0ddd0162b6c82e1e85d01dd11b62569fe0
      12c302b9062b0ee1a659b2d2f1fe89a1886b83a17974f43bc65e569e74f3da0c
    ].join('|')})"))
  end
end
