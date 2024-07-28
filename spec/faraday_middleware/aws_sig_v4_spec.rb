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
        4c11e411098ddf7c014bc536ce75cc7109db3c514fc909e24c872abc6ae62d13
        ae563772700a7de79f3564e3b4b5df36fc978ad09cba895dbd1cad96df54536e
        d6930fe3394253f553611b2fd52c32fd7571de73b76125436df259abd5fb5a03
        a8dffd8ba1c96eb2c23ef008e5e73e5211a81a722e04df06fdaa9bf19f6673cf
        6f34b47074a064ed0aac24a25573ceaf25355716ac58b366cf3de1bc16765933
        fd241cfacbbccff1a3c5a2b91292631bcd7fcb3a3f524de719e63b4225a0f12c
        3efcb25e63b9d6ac973426dedd7469a1261f4d50bfdf2f74452cc7321ea7966a
        5bace964e6e9c075f0469a66f51fc7119b9fa2f483df8c7371b34443b638d98c
        054a0bcfe06a884daf1d9784ce117b31eb5a3d1d87e955be2c733336d7b269ab
        bd052b7171345817f537ab38cb17a08149e8a0d47c5ddfdb0876e63b510febf7
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
          07ca1b4ea43634570e49674baec593b832b7703b11e69c5e036a6b3123fa5746
          5ba5f2e7c34bda12226ae327475be7c823599987f279c1f93bf03332ffcb4258
          5f94f681902b3017b38f73603775fcaad100f64b0ff1f59d343118d909333983
          dc0a4e7ffc9a13371b277b0008149e39d9404df2745d18d2c53c743c3cb3d2d7
          791b5e602a4c3567843ad43b001d4847e3067c1e6a66eef8148d3458edaf9421
          6352ba8fa2de2cf89b5c534a27936b76cd7ff9d1485cb7e232521bcb9d7ce83a
          0f90b894566c809c9534910c95e8757ae6e02bda13ea14b9439389a8a937b52c
          94c0b7b3aa2f30a459b7e24da7e58f93cfd615b2f1e89f83694185bf9ef22b58
          3ad0b3c6938517ff5ded326d7b50fc1b433c953a5407e66c304270ca8116b1df
          d63769da2dff24e9183fcd5dd9be07bb00615f04554c1617fe0bc41a7b137791
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
          56c169dbf61ee1a75517948184e9ee213700514f76753c1e8e9556809b3d4a27
          aa8c31832063efe3939d1c828cb60d503a6e46e15fcae6ba18cc3fd9d9827a38
          a91b0f89ba554f2fe2c6f2246ddb709a3521263aa21f6a686ea7e0970c549363
          95d4570e6e394fd7eed0372d64508dff8e41068103a6b19f65e4553ffa79628c
          0ea722c247c3d73debf39125c395ebcc76fbce24b0dcd57382618dcace090f34
          2209b3053cc15a638af44d9a9df53931fd28273960ba6b8edc7de006ec627f9a
          c379ac6671a9c66f537d5214a899613da11c62b29559fa2b85dfff36b3433e9a
          961e49aa94c628e3e4fa153ae9c0a841e65f79882c7cdd6007a123f2bb8d7182
          ef10f69334285b89c8b56b2b2294c9707e5841696a4549314d4321f782d111c3
          3d5bd14f0bdc9d1b9dc149a122a785144f5aec9c4d7c27c8aad8dcbc1c64d9d4
        ].join('|')})"
      end

      let(:params) { { foo: 'bar', zoo: 'baz' } }

      it { is_expected.to eq response }
    end
  end
end
