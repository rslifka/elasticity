describe Elasticity::AwsRequestV4 do

  before do
    Timecop.freeze(Time.at(1315611360))
  end

  after do
    Timecop.return
  end

  subject do
    Elasticity::AwsRequestV4.new(
      Elasticity::AwsSession.new('access', 'secret'),
      {:operation => 'DescribeJobFlows', :job_flow_ids => ['TEST_JOBFLOW_ID']}
    )
  end

  describe '#url' do
    it 'should construct a proper endpoint' do
      subject.url.should == 'https://elasticmapreduce.us-east-1.amazonaws.com'
    end
  end

  describe '#headers' do
    it 'should create the proper headers' do
      subject.headers.should == {
        'Authorization' => "AWS4-HMAC-SHA256 Credential=access/20110909/us-east-1/elasticmapreduce/aws4_request, SignedHeaders=content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target, Signature=#{subject.send(:aws_v4_signature)}",
        'Content-Type' => 'application/x-amz-json-1.1',
        'Host' => 'elasticmapreduce.us-east-1.amazonaws.com',
        'User-Agent' => "elasticity/#{Elasticity::VERSION}",
        'X-Amz-Content-SHA256' => Digest::SHA256.hexdigest(subject.payload),
        'X-Amz-Date' => '20110909T233600Z',
        'X-Amz-Target' => 'ElasticMapReduce.DescribeJobFlows',
      }
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