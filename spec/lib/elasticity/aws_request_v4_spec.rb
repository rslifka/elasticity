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
      {:operation => 'RunJobFlow', :name => 'Elasticity Job Flow'}
    )
  end

  describe '#url' do
    it 'should construct a proper endpoint' do
      subject.url.should == 'https://elasticmapreduce.us-east-1.amazonaws.com'
    end
  end

  describe '#headers' do
    xit 'should create the proper headers'
  end

  describe '#payload' do
    xit 'should create the proper payload'
  end

  describe '.canonical_request' do
    it 'should create the proper canonical request' do
      subject.send(:canonical_request).should ==
        <<-CANONICAL_REQUEST
POST
/

content-type:application/x-www-form-urlencoded; charset=utf8
host:elasticmapreduce.us-east-1.amazonaws.com

content-type;host
a428ce5f6e2eb121a9136c5a9b59910b4e49b7629bcbc9763bd401cfb14d6e31
      CANONICAL_REQUEST
    end
  end

  describe '.string_to_sign' do
    it 'should create the proper string to sign' do
      subject.send(:string_to_sign).should ==
        <<-STRING_TO_SIGN
AWS4-HMAC-SHA256
20110909T233600Z
20110909/us-east-1/elb/aws4_request
5ecca45fcd443b7a1f2c24fa322a6daf160f2b6aa0d57916f3a0507a61d4f5b7
      STRING_TO_SIGN
    end
  end

  describe '.aws_v4_signature' do
    it 'should create the proper signature' do
      subject.send(:aws_v4_signature).should == '4ec46bd474c2bb4b47ee8cf6edc8c7d829fe96f5ac98742535c86a4a86a35d52'
    end
  end

end