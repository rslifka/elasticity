describe Elasticity::SimpleJob do

  subject do
    Elasticity::SimpleJob.new("access", "secret")
  end

  its(:action_on_failure)     { should == "TERMINATE_JOB_FLOW" }
  its(:aws_access_key_id)     { should == "access" }
  its(:aws_secret_access_key) { should == "secret" }
  its(:ec2_key_name)          { should == "default" }
  its(:hadoop_version)        { should == "0.20" }
  its(:instance_count)        { should == 2 }
  its(:log_uri)               { should == nil }
  its(:master_instance_type)  { should == "m1.small" }
  its(:name)                  { should == "Elasticity Job" }
  its(:slave_instance_type)   { should == "m1.small" }

  describe "#jobflow_bootstrap_action" do
    it "should be a proper bootstrap action" do
      subject.send(:jobflow_bootstrap_action, "OPTION1", "VALUE1").should == {
        :name => "Elasticity Bootstrap Action (Configure Hadoop)",
        :script_bootstrap_action => {
          :path => "s3n://elasticmapreduce/bootstrap-actions/configure-hadoop",
          :args => ["OPTION1", "VALUE1"]
        }
      }
    end
  end

  describe "#jobflow_bootstrap_actions" do

    context "when bootstrap actions (same option values) are specified" do
      before do
        subject.add_hadoop_bootstrap_action("OPTION1", "VALUE1")
        subject.add_hadoop_bootstrap_action("OPTION1", "VALUE2")
      end
      it "should be an array of bootstrap actions" do
        subject.send(:jobflow_bootstrap_actions).should == [
          subject.send(:jobflow_bootstrap_action, "OPTION1", "VALUE1"),
          subject.send(:jobflow_bootstrap_action, "OPTION1", "VALUE2"),
        ]
      end
    end

    context "when bootstrap actions (different option values) are specified" do
      before do
        subject.add_hadoop_bootstrap_action("OPTION1", "VALUE1")
        subject.add_hadoop_bootstrap_action("OPTION2", "VALUE2")
      end
      it "should be an array of bootstrap actions" do
        subject.send(:jobflow_bootstrap_actions).should == [
          subject.send(:jobflow_bootstrap_action, "OPTION1", "VALUE1"),
          subject.send(:jobflow_bootstrap_action, "OPTION2", "VALUE2"),
        ]
      end
    end

    context "when bootstrap actions are not specified" do
      it "should be an empty array" do
        subject.send(:jobflow_bootstrap_actions).should == []
      end
    end

  end

  describe "#jobflow_config" do

    before do
      subject.stub(:jobflow_preamble).and_return({:preamble => "PREAMBLE"})
      subject.stub(:jobflow_steps).and_return(["step1", "step2"])
    end

    it "should incorporate the jobflow preamble" do
      subject.send(:jobflow_config).should be_a_hash_including({:preamble => "PREAMBLE"})
    end

    it "should incorporate the steps of the jobflow" do
      subject.send(:jobflow_config).should be_a_hash_including({:steps => ["step1", "step2"]})
    end

    describe "log URI" do
      context "when a log URI is specified" do
        it "should incorporate it into the jobflow config" do
          subject.log_uri = "LOG_URI"
          subject.send(:jobflow_config).should be_a_hash_including({:log_uri => "LOG_URI"})
        end
      end
      context "when a log URI is not specified" do
        it "should not make space for it in the jobflow config" do
          subject.log_uri = nil
          subject.send(:jobflow_config).should_not have_key(:log_uri)
        end
      end
    end

    describe "bootstrap actions" do
      context "when bootstrap actions are specified" do
        it "should incorporate them into the jobflow config" do
          subject.add_hadoop_bootstrap_action("_", "_")
          subject.stub(:jobflow_bootstrap_actions).and_return("BOOTSTRAP_ACTIONS")
          subject.send(:jobflow_config).should be_a_hash_including({:bootstrap_actions => "BOOTSTRAP_ACTIONS"})
        end
      end
      context "when bootstrap actions are not specified" do
        it "should not make space for them in the jobflow config" do
          subject.send(:jobflow_config).should_not have_key(:bootstrap_actions)
        end
      end
    end

  end

end