describe Elasticity::JobFlow do

  subject do
    Elasticity::JobFlow.new("access", "secret")
  end

  its(:action_on_failure) { should == "TERMINATE_JOB_FLOW" }
  its(:aws_access_key_id) { should == "access" }
  its(:aws_secret_access_key) { should == "secret" }
  its(:ec2_key_name) { should == "default" }
  its(:hadoop_version) { should == "0.20" }
  its(:instance_count) { should == 2 }
  its(:log_uri) { should == nil }
  its(:master_instance_type) { should == "m1.small" }
  its(:name) { should == "Elasticity Job Flow" }
  its(:slave_instance_type) { should == "m1.small" }

end