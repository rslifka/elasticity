describe Elasticity::AwsRequest do

  subject do
    Elasticity::AwsRequest.new('aws_access_key_id', 'aws_secret_access_key')
  end

  its(:access_key) { should == 'aws_access_key_id' }
  its(:secret_key) { should == 'aws_secret_access_key' }
  its(:options)    { should == {:secure => true} }

  describe '#sign_params' do
    before do
      Time.stub(:now).and_return(Time.at(1302461096))
    end

    it 'should sign according to AWS rules' do
      signed_params = subject.send(:sign_params, {}, 'GET', 'example.com', '/')
      signed_params.should == 'AWSAccessKeyId=aws_access_key_id&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-04-10T18%3A44%3A56.000Z&Signature=jVLfPS056dNmjpCcikBnPmRHJNZ8YGaI7zdmHWUk658%3D'
    end
  end

  describe '#aws_emr_request' do
    before do
      Time.stub(:now).and_return(Time.at(1302461096))
    end

    describe 'options' do

      context 'when no options are specified' do
        it 'should use the default option values' do
          RestClient.should_receive(:get).with(/^https:\/\/elasticmapreduce.amazonaws.com/)
          subject.aws_emr_request({})
        end
      end

      context 'when :region is specified' do
        let(:region) { 'eu-west-1' }
        let(:request) { Elasticity::AwsRequest.new('aws_access_key_id', 'aws_secret_access_key', :region => region) }

        it 'should request against that region' do
          RestClient.should_receive(:get).with(/elasticmapreduce\.#{region}\.amazonaws\.com/)
          request.aws_emr_request({})
        end
      end

      context 'when :secure is false' do
        let(:request) { Elasticity::AwsRequest.new('aws_access_key_id', 'aws_secret_access_key', :secure => false) }

        it 'should use the value to determine the request type' do
          RestClient.should_receive(:get).with(/^http:/)
          request.aws_emr_request({})
        end
      end

      context 'when :secure is true' do
        let(:request) { Elasticity::AwsRequest.new('aws_access_key_id', 'aws_secret_access_key', :secure => true) }

        it 'should use the value to determine the request type' do
          RestClient.should_receive(:get).with(/^https:/)
          request.aws_emr_request({})
        end
      end
    end
  end

  describe '#==' do
    let(:same_object) { subject }
    let(:same_values) { Elasticity::AwsRequest.new('aws_access_key_id', 'aws_secret_access_key', {}) }
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
      Elasticity::EMR.send(:convert_ruby_to_aws, add_jobflow_steps_params).should == expected_result
    end
  end
    
end
