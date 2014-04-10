describe Elasticity::ScriptStep do

  it { should be_a Elasticity::CustomJarStep }

  subject { Elasticity::ScriptStep.new('script_location', 'arg1', 'arg2') }

  its(:name) { should == 'Elasticity Script Step' }
  its(:jar) { should == 's3://elasticmapreduce/libs/script-runner/script-runner.jar' }
  its(:arguments) { should == ['script_location arg1 arg2'] }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }

end