describe Elasticity::S3DistCpStep do

  it { should be_a Elasticity::CustomJarStep }

  subject { Elasticity::S3DistCpStep.new({'arg1' => 'value1', :arg2 => 'value2'}) }

  its(:name) { should == 'Elasticity S3DistCp Step' }
  its(:jar) { should == '/home/hadoop/lib/emr-s3distcp-1.0.jar' }
  its(:arguments) { should == %w(--arg arg1 --arg value1 --arg arg2 --arg value2) }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }

end