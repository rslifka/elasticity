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

end