require 'spec_helper'

describe Elasticity::HiveJob do

  describe ".new" do

    it "should have good defaults" do
      hive = Elasticity::HiveJob.new("access", "secret")
      hive.aws_access_key_id.should == "access"
      hive.aws_secret_access_key.should == "secret"
      hive.ec2_key_name.should == "default"
      hive.hadoop_version.should == "0.20"
      hive.instance_count.should == 2
      hive.master_instance_type.should == "m1.small"
      hive.name.should == "Elasticity Hive Job"
      hive.slave_instance_type.should == "m1.small"
      hive.action_on_failure.should == "TERMINATE_JOB_FLOW"
      hive.log_uri.should == nil
    end

  end

  describe "#run" do

    it "should run the script with the specified variables and return the jobflow_id" do
      aws = Elasticity::EMR.new("", "")
      aws.should_receive(:run_job_flow).with({
        :name => "Elasticity Hive Job",
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
              :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
              :args => [
                "s3://elasticmapreduce/libs/hive/hive-script",
                  "--base-path",
                  "s3://elasticmapreduce/libs/hive/",
                  "--install-hive"
              ],
            },
            :name => "Setup Hive"
          },
            {
              :action_on_failure => "CONTINUE",
              :hadoop_jar_step => {
                :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
                :args => [
                  "s3://elasticmapreduce/libs/hive/hive-script",
                    "--run-hive-script",
                    "--args",
                    "-f", "s3n://slif-hive/test.q",
                    "-d", "OUTPUT=s3n://slif-test/output",
                    "-d", "XREFS=s3n://slif-test/xrefs"
                ],
              },
              :name => "Run Hive Script"
            }
        ]
      }).and_return("new_jobflow_id")
      Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)

      hive = Elasticity::HiveJob.new("access", "secret")
      hive.log_uri = "s3n://slif-test/output/logs"
      hive.action_on_failure = "CONTINUE"
      jobflow_id = hive.run('s3n://slif-hive/test.q', {
        'OUTPUT' => 's3n://slif-test/output',
        'XREFS' => 's3n://slif-test/xrefs'
      })
      jobflow_id.should == "new_jobflow_id"
    end

  end

  describe "integration happy path" do
    use_vcr_cassette "hive_job/hive_ads", :record => :none
    it "should kick off the sample Amazion EMR Hive application" do
      hive = Elasticity::HiveJob.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
      hive.ec2_key_name = "sharethrough_dev"
      jobflow_id = hive.run("s3n://elasticmapreduce/samples/hive-ads/libs/model-build.q", {
        "INPUT"  => "s3n://elasticmapreduce/samples/hive-ads/tables",
        "LIBS"   => "s3n://elasticmapreduce/samples/hive-ads/libs",
        "OUTPUT" => "s3n://slif-elasticity/hive-ads/output/2011-04-19"
      })
      jobflow_id.should == "j-1UUVYMHBLKEGN"
    end
  end

end