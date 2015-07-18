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
            ENV.stub(:[]).with('AWS_SECURITY_TOKEN')
          end
          it 'should set access and secret keys' do
            expect(default_values.access_key).to eq('ENV_ACCESS')
            expect(default_values.secret_key).to eq('ENV_SECRET')
          end
        end

        context 'when access and secret key are nil' do
          let(:nil_values) { Elasticity::AwsSession.new(nil, nil) }
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('ENV_ACCESS')
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('ENV_SECRET')
            ENV.stub(:[]).with('AWS_SECURITY_TOKEN')
          end
          it 'should set access and secret keys' do
            expect(nil_values.access_key).to eq('ENV_ACCESS')
            expect(nil_values.secret_key).to eq('ENV_SECRET')
          end
        end

        context 'when security key set' do
          let(:nil_values) { Elasticity::AwsSession.new(nil, nil) }
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('ENV_ACCESS')
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('ENV_SECRET')
            ENV.stub(:[]).with('AWS_SECURITY_TOKEN').and_return('ENV_SECURITY_TOKEN')
          end
          it 'should set security token' do
            expect(nil_values.security_token).to eq('ENV_SECURITY_TOKEN')
          end
        end

      end

      context 'when the environment variables are not set' do
        let(:missing_something) { Elasticity::AwsSession.new }
        context 'when the access key is not set' do
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return(nil)
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('_')
            ENV.stub(:[]).with('AWS_SECURITY_TOKEN')
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
            ENV.stub(:[]).with('AWS_SECURITY_TOKEN')
          end
          it 'should raise an error' do
            expect {
              missing_something.access_key
            }.to raise_error(Elasticity::MissingKeyError, 'Please provide a secret key or set AWS_SECRET_ACCESS_KEY.')
          end
        end
        context 'when the security token is not set' do
          before do
            ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('_')
            ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('_')
            ENV.stub(:[]).with('AWS_SECURITY_TOKEN')
          end
          it 'should return nothing' do
            expect(missing_something.security_token).not_to be
          end
        end
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
        Elasticity::AwsSession.new('_', '_', {:region => 'us-west-1'})
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

    end

  end

end
