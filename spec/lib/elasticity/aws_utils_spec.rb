describe Elasticity::AwsUtils do

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
      Elasticity::AwsUtils.send(:convert_ruby_to_aws, add_jobflow_steps_params).should == expected_result
    end
  end

end