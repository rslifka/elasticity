describe Elasticity::SetupHadoopDebuggingStep do

  it { should be_a Elasticity::CustomJarStep }

  its(:name) { should == 'Elasticity Setup Hadoop Debugging' }
  its(:jar) { should == 's3://elasticmapreduce/libs/script-runner/script-runner.jar' }
  its(:arguments) { should == ['s3://elasticmapreduce/libs/state-pusher/0.1/fetch'] }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }

end