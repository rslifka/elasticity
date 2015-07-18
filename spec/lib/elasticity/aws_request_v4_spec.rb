describe Elasticity::AwsRequestV4 do

  before do
    Timecop.freeze(Time.at(1315611360))

    Elasticity.configure do |c|
      c.access_key = 'access'
      c.secret_key = 'secret'
    end
  end

  after do
    Timecop.return
  end

  subject do
    Elasticity::AwsRequestV4.new(
      Elasticity::AwsSession.new,
      {:operation => 'DescribeJobFlows', :job_flow_ids => ['TEST_JOBFLOW_ID']}
    )
  end

  describe '.initialize' do

    describe 'access key' do
      context 'when not provided' do
        it 'should be an error' do
          Elasticity.configure do |c|
            c.access_key = nil
          end
          expect {
            Elasticity::AwsRequestV4.new(nil, {})
          }.to raise_error(ArgumentError, '.access_key must be set in the configuration block')
        end
      end
    end

    describe 'secret key' do
      context 'when not provided' do
        it 'should be an error' do
          Elasticity.configure do |c|
            c.secret_key = nil
          end
          expect {
            Elasticity::AwsRequestV4.new(nil, {})
          }.to raise_error(ArgumentError, '.secret_key must be set in the configuration block')
        end
      end
    end

  end

  describe '#url' do
    it 'should construct a proper endpoint' do
      subject.url.should == 'https://elasticmapreduce.us-east-1.amazonaws.com'
    end
  end

  describe '#headers' do

    let(:base_headers) {
      {
        'Authorization' => "AWS4-HMAC-SHA256 Credential=access/20110909/us-east-1/elasticmapreduce/aws4_request, SignedHeaders=content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target, Signature=#{subject.send(:aws_v4_signature)}",
        'Content-Type' => 'application/x-amz-json-1.1',
        'Host' => 'elasticmapreduce.us-east-1.amazonaws.com',
        'User-Agent' => "elasticity/#{Elasticity::VERSION}",
        'X-Amz-Content-SHA256' => Digest::SHA256.hexdigest(subject.payload),
        'X-Amz-Date' => '20110909T233600Z',
        'X-Amz-Target' => 'ElasticMapReduce.DescribeJobFlows'
      }
    }

    context 'when a security token is specified' do
      it 'should create the proper headers' do
        Elasticity.configure {|c| c.security_token = 'SECURITY_TOKEN' }
        subject.headers.should == base_headers.merge('X-Amz-Security-Token' => 'SECURITY_TOKEN')
      end
    end

    context 'when a security token is not specified' do
      it 'should create the proper headers' do
        Elasticity.configure {|c| c.security_token = nil }
        subject.headers.should == base_headers
      end
    end
  end

  describe '#payload' do
    it 'should create the proper payload' do
      subject.payload.should == '{"JobFlowIds":["TEST_JOBFLOW_ID"]}'
    end
  end

  describe '.canonical_request' do
    it 'should create the proper canonical request' do
      subject.send(:canonical_request).should == [
        'POST',
        '/',
        '',
        'content-type:application/x-amz-json-1.1',
        'host:elasticmapreduce.us-east-1.amazonaws.com',
        "user-agent:elasticity/#{Elasticity::VERSION}",
        "x-amz-content-sha256:#{Digest::SHA256.hexdigest(subject.payload)}",
        'x-amz-date:20110909T233600Z',
        'x-amz-target:ElasticMapReduce.DescribeJobFlows',
        '',
        'content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target',
        "#{Digest::SHA256.hexdigest(subject.payload)}"
      ].join("\n")
    end
  end

  describe '.string_to_sign' do
    it 'should create the proper string to sign' do
      subject.send(:string_to_sign).should == [
        'AWS4-HMAC-SHA256',
        '20110909T233600Z',
        '20110909/us-east-1/elasticmapreduce/aws4_request',
        "#{Digest::SHA256.hexdigest(subject.send(:canonical_request))}"
      ].join("\n")
    end
  end

  describe '.aws_v4_signature' do
    it 'should create the proper signature' do
      subject.send(:aws_v4_signature).should == '05abf0e77ad6f8ce08449e678c2ba2822463599196abf0bdbdfef2ce21b5b6f3'
    end
  end

end