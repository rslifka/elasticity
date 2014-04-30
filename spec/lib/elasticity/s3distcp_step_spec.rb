describe Elasticity::S3DistCpStep do

  it { should be_a Elasticity::CustomJarStep }

  its(:name) { should == 'Elasticity S3DistCp Step' }
  its(:jar) { should == '/home/hadoop/lib/emr-s3distcp-1.0.jar' }
  its(:arguments) { should == [] }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }

end