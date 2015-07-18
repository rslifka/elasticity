describe Elasticity::AwsSession do

  before do
    Timecop.freeze(Time.at(1302461096))

    Elasticity.configure do |c|
      c.access_key = 'access'
      c.secret_key = 'secret'
    end
  end

  after do
    Timecop.return
  end

  describe '#initialize' do

    context 'when access and/or secret keys are provided' do
      it 'should set them to the provided values' do
        subject.region.should == 'us-east-1'
      end
    end

    context 'when :region is nil' do
      it 'should be an error' do
        expect {
          Elasticity::AwsSession.new(:region => nil)
        }.to raise_error Elasticity::MissingRegionError, 'A valid :region is required to connect to EMR'
      end
    end

    context 'when :region is specified' do
      it 'should be assigned' do
        Elasticity::AwsSession.new(:region => 'TEST_REGION').region.should == 'TEST_REGION'
      end
    end

  end

  describe '#host' do

    context 'when the region is not specified' do
      it 'should use the default value' do
        expect(subject.host).to eq('elasticmapreduce.us-east-1.amazonaws.com')
      end
    end

    context 'when the region is specified' do
      let(:request_with_region) do
        Elasticity::AwsSession.new(:region => 'us-west-1')
      end
      it 'should incorporate the region into the hostname' do
        request_with_region.host.should == 'elasticmapreduce.us-west-1.amazonaws.com'
      end
    end

  end

  describe '#submit' do

    context 'when there is not an error with the request' do
      before do
        @request = Elasticity::AwsRequestV4.new(subject, {})
        @request.should_receive(:url).and_return('TEST_URL')
        @request.should_receive(:payload).and_return('TEST_PAYLOAD')
        @request.should_receive(:headers).and_return('TEST_HEADERS')

        Elasticity::AwsRequestV4.should_receive(:new).with(subject, {}).and_return(@request)
        RestClient.should_receive(:post).with('TEST_URL', 'TEST_PAYLOAD', 'TEST_HEADERS')
      end

      it 'should POST a properly assembled request' do
        subject.submit({})
      end
    end

    context 'when there is an EMR error with the request' do
      let(:error_message) { 'ERROR_MESSAGE' }
      let(:error_type) { 'ERROR_TYPE' }
      let(:error_json) do
        <<-JSON
          { "__type" : "#{error_type}", "message" : "#{error_message}" }
        JSON
      end
      let(:error) do
        RestClient::BadRequest.new.tap do |error|
          error.stub(:http_body => error_json)
        end
      end

      it 'should raise an Argument error with the body of the error' do
        RestClient.should_receive(:post).and_raise(error)
        expect {
          subject.submit({})
        }.to raise_error(ArgumentError, "AWS EMR API Error (#{error_type}): #{error_message}")
      end
    end

  end

  describe '#==' do

    describe 'basic equality checks with subject' do
      let(:same_object) { subject }
      let(:same_values) { Elasticity::AwsSession.new }
      let(:diff_type) { Object.new }

      it { should == same_object }
      it { should == same_values }
      it { should_not == diff_type }
    end

    describe 'deep comparisons' do

      it 'should fail on host check' do
        aws1 = Elasticity::AwsSession.new(:region => 'us-east-1')
        aws2 = Elasticity::AwsSession.new(:region => 'us-west-1')
        aws1.should_not == aws2
      end

    end

  end

end
