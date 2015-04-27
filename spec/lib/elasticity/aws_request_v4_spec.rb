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
    it 'should create the proper headers' do
      subject.headers.should == {
        :content_type => 'application/x-www-form-urlencoded; charset=utf-8',
        :Authorization => 'AWS4-HMAC-SHA256 Credential=access/20110909/us-east-1/emr/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=4452b104157f99c871c583305e70773c952d7dbd2e67887a225da6834bb20793',
        'X-Amz-Date' => '20110909T233600Z'
      }
    end
  end

  describe '#payload' do
    xit 'should create the proper payload'
  end

  describe '.canonical_request' do
    it 'should create the proper canonical request' do
      subject.send(:canonical_request).should == '' \
      "POST\n" \
      "/\n" \
      "\n" \
      "content-type:application/x-www-form-urlencoded; charset=utf8\n" \
      "host:elasticmapreduce.us-east-1.amazonaws.com\n" \
      "x-amz-date:20110909T233600Z\n" \
      "\n" \
      "content-type;host;x-amz-date\n" \
      "a428ce5f6e2eb121a9136c5a9b59910b4e49b7629bcbc9763bd401cfb14d6e31"
    end
  end

  describe '.string_to_sign' do
    it 'should create the proper string to sign' do
      subject.send(:string_to_sign).should == '' \
      "AWS4-HMAC-SHA256\n" \
      "20110909T233600Z\n" \
      "20110909/us-east-1/emr/aws4_request\n" \
      '6b713b1663621815b852ee7880d320b65325e4972116290e3ab28288c5c7d76f'
    end
  end

  describe '.aws_v4_signature' do
    it 'should create the proper signature' do
      subject.send(:aws_v4_signature).should == '4452b104157f99c871c583305e70773c952d7dbd2e67887a225da6834bb20793'
    end
  end

end