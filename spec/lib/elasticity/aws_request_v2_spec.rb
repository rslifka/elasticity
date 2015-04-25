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

  describe '.convert_ruby_to_aws' do
    it 'should convert the params' do
      add_jobflow_steps_params = {
        :job_flow_id => 'j-1',
        :steps => [
          {
            :action_on_failure => 'CONTINUE',
            :name => 'First New Job Step',
            :hadoop_jar_step => {
              :args => %w(arg1 arg2 arg3),
              :jar => 'first_step.jar',
              :main_class => 'first_class.jar'
            }
          },
          {
            :action_on_failure => 'CANCEL_AND_WAIT',
            :name => 'Second New Job Step',
            :hadoop_jar_step => {
              :args => %w(arg4 arg5 arg6),
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
      Elasticity::AwsRequestV2.send(:convert_ruby_to_aws, add_jobflow_steps_params).should == expected_result
    end
  end

end