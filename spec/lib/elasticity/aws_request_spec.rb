describe Elasticity::AwsRequest do

  before do
    Time.stub(:now).and_return(Time.at(1302461096))
  end

  subject do
    Elasticity::AwsRequest.new('access', 'secret')
  end

  its(:access_key) { should == 'access' }
  its(:secret_key) { should == 'secret' }

  describe '#host' do

    context 'when the region is not specified' do
      its(:host) { should == 'elasticmapreduce.amazonaws.com' }
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
      signed_params = subject.send(:sign_params, {}, 'GET')
      signed_params.should == 'AWSAccessKeyId=access&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-04-10T18%3A44%3A56.000Z&Signature=qZmS%2BWVb8ksweMcIHNLLybOeafrSbPaVX9H8rJ5qPO0%3D'
    end
  end

  describe '#submit' do

    describe

    it 'should convert the ruby-style parameters to AWS-style parameters' do

    end

    describe 'request assembly' do
      let(:request) do
        Elasticity::AwsRequest.new('_', '_').tap do |r|
          r.stub(:sign_params => 'SIGNED_PARAMS')
          r.instance_variable_set(:@host, 'HOSTNAME')
          r.instance_variable_set(:@protocol, 'PROTOCOL')
        end
      end

      it 'should GET a properly assembled request' do
        RestClient.should_receive(:get).with('PROTOCOL://HOSTNAME?SIGNED_PARAMS')
        request.submit({})
      end
    end

  end

  describe '#==' do
    let(:same_object) { subject }
    let(:same_values) { Elasticity::AwsRequest.new('access', 'secret', {}) }
    let(:diff_type) { Object.new }

    it { should == same_object }
    it { should == same_values }
    it { should_not == diff_type }

    it 'should be false on deep comparison' do
      {
        :@access_key => '_',
        :@secret_key => '_',
        :@options => {:foo => :bar}
      }.each do |variable, value|
        other = Elasticity::AwsRequest.new('aws_access_key_id', 'aws_secret_access_key', {})
        other.instance_variable_set(variable, value)
        subject.should_not == other
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
