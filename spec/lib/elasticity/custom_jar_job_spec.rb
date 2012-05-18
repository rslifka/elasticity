describe Elasticity::CustomJarJob do

  subject do
    Elasticity::CustomJarJob.new("access", "secret", "jar")
  end

  it { should be_a_kind_of Elasticity::SimpleJob }

  its(:jar)  { should == "jar" }
  its(:name) { should == "Elasticity Custom Jar Job" }

  describe "#run" do

    context "when there are arguments provided" do
      it "should run the script with the specified variables and return the jobflow_id" do
        aws = Elasticity::EMR.new("", "")
        aws.should_receive(:run_job_flow).with(
          {
            :name => "Elasticity Custom Jar Job",
            :log_uri => "s3n://slif-test/output/logs",
            :instances => {
              :ec2_key_name => "default",
              :hadoop_version => "0.20",
              :instance_count => 2,
              :master_instance_type => "m1.small",
              :slave_instance_type => "m1.small",
            },
            :steps => [
              {
                :action_on_failure => "TERMINATE_JOB_FLOW",
                :hadoop_jar_step => {
                  :jar => "s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar",
                  :args => [
                    "s3n://elasticmapreduce/samples/cloudburst/input/s_suis.br",
                      "s3n://elasticmapreduce/samples/cloudburst/input/100k.br",
                      "s3n://slif_hadoop_test/cloudburst/output/2011-12-09",
                  ],
                },
                :name => "Execute Custom Jar"
              }
            ]
          }).and_return("new_jobflow_id")
        Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)

        custom_jar = Elasticity::CustomJarJob.new("access", "secret", "s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar")
        custom_jar.log_uri = "s3n://slif-test/output/logs"
        custom_jar.action_on_failure = "TERMINATE_JOB_FLOW"
        custom_jar.arguments = [
          "s3n://elasticmapreduce/samples/cloudburst/input/s_suis.br",
            "s3n://elasticmapreduce/samples/cloudburst/input/100k.br",
            "s3n://slif_hadoop_test/cloudburst/output/2011-12-09",
        ]
        jobflow_id = custom_jar.run
        jobflow_id.should == "new_jobflow_id"
      end
    end

    context "when there are no arguments provided" do
      it "should run the script with the specified variables and return the jobflow_id" do
        aws = Elasticity::EMR.new("", "")
        aws.should_receive(:run_job_flow).with(
          {
            :name => "Elasticity Custom Jar Job",
            :log_uri => "s3n://slif-test/output/logs",
            :instances => {
              :ec2_key_name => "default",
              :hadoop_version => "0.20",
              :instance_count => 2,
              :master_instance_type => "m1.small",
              :slave_instance_type => "m1.small",
            },
            :steps => [
              {
                :action_on_failure => "TERMINATE_JOB_FLOW",
                :hadoop_jar_step => {
                  :jar => "s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar"
                },
                :name => "Execute Custom Jar"
              }
            ]
          }).and_return("new_jobflow_id")
        Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)

        custom_jar = Elasticity::CustomJarJob.new("access", "secret", "s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar")
        custom_jar.log_uri = "s3n://slif-test/output/logs"
        custom_jar.action_on_failure = "TERMINATE_JOB_FLOW"
        jobflow_id = custom_jar.run
        jobflow_id.should == "new_jobflow_id"
      end
    end

  end

  describe "integration happy path" do
    use_vcr_cassette "custom_jar_job/cloudburst", :record => :none
    it "should kick off the sample Amazion EMR Hive application" do
      custom_jar = Elasticity::CustomJarJob.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY, "s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar")
      custom_jar.ec2_key_name = "sharethrough_dev"
      custom_jar.arguments = [
        "s3n://elasticmapreduce/samples/cloudburst/input/s_suis.br",
          "s3n://elasticmapreduce/samples/cloudburst/input/100k.br",
          "s3n://slif_hadoop_test/cloudburst/output/2011-12-09",
      ]
      jobflow_id = custom_jar.run
      jobflow_id.should == "j-1IU6NM8OUPS9I"
    end
  end

end