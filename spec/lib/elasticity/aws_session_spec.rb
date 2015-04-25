describe Elasticity::AwsSession do

  before do
    Timecop.freeze(Time.at(1302461096))
  end

  after do
    Timecop.return
  end

  subject do
    Elasticity::AwsSession.new('access', 'secret')
  end

  describe '#initialize' do

    context 'when access and/or secret keys are provided' do
      it 'should set them to the provided values' do
        subject.access_key.should == 'access'
        subject.secret_key.should == 'secret'
        subject.region.should == 'us-east-1'
      end
    end

    context 'when :region is nil' do
      it 'should be an error' do
        expect {
          Elasticity::AwsSession.new('_', '_', :region => nil)
        }.to raise_error Elasticity::MissingRegionError, 'A valid :region is required to connect to EMR'
      end
    end

    context 'when :region is specified' do
      Elasticity::AwsSession.new('_', '_', :region => 'TEST_REGION').region.should == 'TEST_REGION'
    end

    context 'when either access or secret key is not provided or nil' do

      context 'when the proper environment variables are set' do

        context 'when access and secret key are not provided' do
          let(:default_values) { Elasticity::AwsSession.new }
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('ENV_ACCESS')
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('ENV_SECRET')
          end
          it 'should set access and secret keys' do
            default_values.access_key.should == 'ENV_ACCESS'
            default_values.secret_key.should == 'ENV_SECRET'
          end
        end

        context 'when access and secret key are nil' do
          let(:nil_values) { Elasticity::AwsSession.new(nil, nil) }
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('ENV_ACCESS')
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('ENV_SECRET')
          end
          it 'should set access and secret keys' do
            nil_values.access_key.should == 'ENV_ACCESS'
            nil_values.secret_key.should == 'ENV_SECRET'
          end
        end

      end

      context 'when the environment variables are not set' do
        let(:missing_something) { Elasticity::AwsSession.new }
        context 'when the access key is not set' do
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return(nil)
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('_')
          end
          it 'should raise an error' do
            expect {
              missing_something.access_key
            }.to raise_error(Elasticity::MissingKeyError, 'Please provide an access key or set AWS_ACCESS_KEY_ID.')
          end
        end
        context 'when the secret key is not set' do
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('_')
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return(nil)
          end
          it 'should raise an error' do
            expect {
              missing_something.access_key
            }.to raise_error(Elasticity::MissingKeyError, 'Please provide a secret key or set AWS_SECRET_ACCESS_KEY.')
          end
        end
      end

    end

  end

  describe '#host' do

    context 'when the region is not specified' do
      its(:host) { should == 'elasticmapreduce.us-east-1.amazonaws.com' }
    end

    context 'when the region is specified' do
      let(:request_with_region) do
        Elasticity::AwsSession.new('_', '_', {:region => 'us-west-1'})
      end
      it 'should incorporate the region into the hostname' do
        request_with_region.host.should == 'elasticmapreduce.us-west-1.amazonaws.com'
      end
    end

  end

  describe '#protocol' do

    context 'when :secure is not specified' do
      let(:default_request) { Elasticity::AwsSession.new('_', '_') }
      it 'should be https by default' do
        default_request.protocol.should == 'https'
      end
    end

    context 'when :secure is specified' do

      context 'when :secure is truthy' do
        let(:secure_request) { Elasticity::AwsSession.new('_', '_', {:secure => true}) }
        it 'should be https' do
          secure_request.protocol.should == 'https'
        end
      end

      context 'when :secure is falsey' do
        let(:insecure_request) { Elasticity::AwsSession.new('_', '_', {:secure => false}) }
        it 'should be http' do
          insecure_request.protocol.should == 'http'
        end
      end

    end

  end

  describe '#submit' do

    context 'when there is not an error with the request' do
      before do
        @request = Elasticity::AwsRequestV2.new(subject, {})
        @request.should_receive(:url).and_return('TEST_URL')
        @request.should_receive(:payload).and_return('TEST_PAYLOAD')
        @request.should_receive(:headers).and_return('TEST_HEADERS')

        Elasticity::AwsRequestV2.should_receive(:new).with(subject, {}).and_return(@request)
        RestClient.should_receive(:post).with('TEST_URL', 'TEST_PAYLOAD', 'TEST_HEADERS')
      end

      it 'should POST a properly assembled request' do
        subject.submit({})
      end
    end

    context 'when there is an EMR error with the request' do
      let(:error_message) { 'ERROR_MESSAGE' }
      let(:error_xml) do
        <<-XML
          <ErrorResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
            <Error>
              <Message>#{error_message}</Message>
            </Error>
          </ErrorResponse>
        XML
      end
      let(:error) do
        RestClient::BadRequest.new.tap do |error|
          error.stub(:http_body => error_xml)
        end
      end

      it 'should raise an Argument error with the body of the error' do
        RestClient.should_receive(:post).and_raise(error)
        expect {
          subject.submit({})
        }.to raise_error(ArgumentError, error_message)
      end
    end

  end

  describe '#==' do

    describe 'basic equality checks with subject' do
      let(:same_object) { subject }
      let(:same_values) { Elasticity::AwsSession.new('access', 'secret', {}) }
      let(:diff_type) { Object.new }

      it { should == same_object }
      it { should == same_values }
      it { should_not == diff_type }
    end

    describe 'deep comparisons' do

      it 'should fail on access key check' do
        Elasticity::AwsSession.new('access', '_').should_not == Elasticity::AwsSession.new('_', '_')
      end

      it 'should fail on secret key check' do
        Elasticity::AwsSession.new('_', 'secret').should_not == Elasticity::AwsSession.new('_', '_')
      end

      it 'should fail on host check' do
        aws1 = Elasticity::AwsSession.new('_', '_', :region => 'us-east-1')
        aws2 = Elasticity::AwsSession.new('_', '_', :region => 'us-west-1')
        aws1.should_not == aws2
      end

      it 'should fail on protocol check' do
        aws1 = Elasticity::AwsSession.new('_', '_', :secure => true)
        aws2 = Elasticity::AwsSession.new('_', '_', :secure => false)
        aws1.should_not == aws2
      end

    end

  end

end
