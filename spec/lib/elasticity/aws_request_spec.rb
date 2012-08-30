describe Elasticity::AwsRequest do

  before do
    Timecop.freeze(Time.at(1302461096))
  end

  subject do
    Elasticity::AwsRequest.new('access', 'secret')
  end

  describe '#initialize' do

    context 'when access and/or secret keys are provided' do
      it 'should set them to the provided values' do
        subject.access_key.should == 'access'
        subject.secret_key.should == 'secret'
      end
    end

    context 'when either access or secret key is not provided or nil' do

      context 'when the proper environment variables are set' do

        context 'when access and secret key are not provided' do
          let(:default_values) { Elasticity::AwsRequest.new }
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
          let(:nil_values) { Elasticity::AwsRequest.new(nil, nil) }
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
        let(:missing_something) { Elasticity::AwsRequest.new }
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
            }.to raise_error(Elasticity::MissingKeyError, 'Please provide a secret key or set AWS_ACCESS_KEY_ID.')
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
        Elasticity::AwsRequest.new('_', '_', {:region => 'us-west-1'})
      end
      it 'should incorporate the region into the hostname' do
        request_with_region.host.should == 'elasticmapreduce.us-west-1.amazonaws.com'
      end
    end

  end

  describe '#protocol' do

    context 'when :secure is not specified' do
      let(:default_request) { Elasticity::AwsRequest.new('_', '_') }
      it 'should be https by default' do
        default_request.protocol.should == 'https'
      end
    end

    context 'when :secure is specified' do

      context 'when :secure is truthy' do
        let(:secure_request) { Elasticity::AwsRequest.new('_', '_', {:secure => true}) }
        it 'should be https' do
          secure_request.protocol.should == 'https'
        end
      end

      context 'when :secure is falsey' do
        let(:insecure_request) { Elasticity::AwsRequest.new('_', '_', {:secure => false}) }
        it 'should be http' do
          insecure_request.protocol.should == 'http'
        end
      end

    end

  end

  describe '#sign_params' do
    it 'should sign according to AWS rules' do
      signed_params = subject.send(:sign_params, {})
      signed_params.should == 'AWSAccessKeyId=access&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-04-10T18%3A44%3A56.000Z&Signature=t%2BccC38VxCKyk2ROTKo9vnECsntKoU0RBAFklHWP5bE%3D'
    end
  end

  describe '#submit' do

    let(:request) do
      Elasticity::AwsRequest.new('_', '_').tap do |r|
        r.instance_variable_set(:@host, 'HOSTNAME')
        r.instance_variable_set(:@protocol, 'PROTOCOL')
      end
    end

    it 'should POST a properly assembled request' do
      ruby_params = {}
      aws_params = {}
      Elasticity::AwsRequest.should_receive(:convert_ruby_to_aws).with(ruby_params).and_return(ruby_params)
      request.should_receive(:sign_params).with(aws_params).and_return('SIGNED_PARAMS')
      RestClient.should_receive(:post).with('PROTOCOL://HOSTNAME', 'SIGNED_PARAMS', :content_type => 'application/x-www-form-urlencoded; charset=utf-8')
      request.submit(ruby_params)
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
          request.submit({})
        }.to raise_error(ArgumentError, error_message)
      end
    end

  end

  describe '#==' do

    describe 'basic equality checks with subject' do
      let(:same_object) { subject }
      let(:same_values) { Elasticity::AwsRequest.new('access', 'secret', {}) }
      let(:diff_type) { Object.new }

      it { should == same_object }
      it { should == same_values }
      it { should_not == diff_type }
    end

    describe 'deep comparisons' do

      it 'should fail on access key check' do
        Elasticity::AwsRequest.new('access', '_').should_not == Elasticity::AwsRequest.new('_', '_')
      end

      it 'should fail on secret key check' do
        Elasticity::AwsRequest.new('_', 'secret').should_not == Elasticity::AwsRequest.new('_', '_')
      end

      it 'should fail on host check' do
        aws1 = Elasticity::AwsRequest.new('_', '_', :region => 'us-east-1')
        aws2 = Elasticity::AwsRequest.new('_', '_', :region => 'us-west-1')
        aws1.should_not == aws2
      end

      it 'should fail on protocol check' do
        aws1 = Elasticity::AwsRequest.new('_', '_', :secure => true)
        aws2 = Elasticity::AwsRequest.new('_', '_', :secure => false)
        aws1.should_not == aws2
      end

    end

  end

  describe '.convert_ruby_to_aws' do
    it 'should convert the params' do
      add_jobflow_steps_params = {
        :job_flow_id => 'j-1',
        :steps => [
          {
            :action_on_failure => 'CONTINUE',
            :name => 'First New Job Step',
            :hadoop_jar_step => {
              :args => ['arg1', 'arg2', 'arg3',],
              :jar => 'first_step.jar',
              :main_class => 'first_class.jar'
            }
          },
            {
              :action_on_failure => 'CANCEL_AND_WAIT',
              :name => 'Second New Job Step',
              :hadoop_jar_step => {
                :args => ['arg4', 'arg5', 'arg6',],
                :jar => 'second_step.jar',
                :main_class => 'second_class.jar'
              }
            }
        ]
      }
      expected_result = {
        'JobFlowId' => 'j-1',
        'Steps.member.1.Name' => 'First New Job Step',
        'Steps.member.1.ActionOnFailure' => 'CONTINUE',
        'Steps.member.1.HadoopJarStep.Jar' => 'first_step.jar',
        'Steps.member.1.HadoopJarStep.MainClass' => 'first_class.jar',
        'Steps.member.1.HadoopJarStep.Args.member.1' => 'arg1',
        'Steps.member.1.HadoopJarStep.Args.member.2' => 'arg2',
        'Steps.member.1.HadoopJarStep.Args.member.3' => 'arg3',
        'Steps.member.2.Name' => 'Second New Job Step',
        'Steps.member.2.ActionOnFailure' => 'CANCEL_AND_WAIT',
        'Steps.member.2.HadoopJarStep.Jar' => 'second_step.jar',
        'Steps.member.2.HadoopJarStep.MainClass' => 'second_class.jar',
        'Steps.member.2.HadoopJarStep.Args.member.1' => 'arg4',
        'Steps.member.2.HadoopJarStep.Args.member.2' => 'arg5',
        'Steps.member.2.HadoopJarStep.Args.member.3' => 'arg6'
      }
      Elasticity::AwsRequest.send(:convert_ruby_to_aws, add_jobflow_steps_params).should == expected_result
    end
  end

end
