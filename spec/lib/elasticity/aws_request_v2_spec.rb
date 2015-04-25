describe Elasticity::AwsRequestV2 do

  before do
    Timecop.freeze(Time.at(1302461096))
  end

  after do
    Timecop.return
  end

  subject do
    Elasticity::AwsRequestV2.new(
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
        :content_type => 'application/x-www-form-urlencoded; charset=utf-8'
      }
    end
  end

  describe '#payload' do
    it 'should payload up the place' do
      subject.payload.should == 'AWSAccessKeyId=access&Name=Elasticity%20Job%20Flow&Operation=RunJobFlow&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-04-10T18%3A44%3A56.000Z&Signature=5x6YilYHOjgM%2F6nalIOf62txOKoLFGBYyIivoHb%2F27k%3D'
    end
  end

end