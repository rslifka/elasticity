require 'spec_helper'

describe Elasticity::PigJob do

  describe ".new" do

    it "should have good defaults" do
      hive = Elasticity::PigJob.new("access", "secret")
      hive.aws_access_key_id.should == "access"
      hive.aws_secret_access_key.should == "secret"
      hive.ec2_key_name.should == "default"
      hive.hadoop_version.should == "0.20"
      hive.instance_count.should == 2
      hive.master_instance_type.should == "m1.small"
      hive.name.should == "Elasticity Pig Job"
      hive.slave_instance_type.should == "m1.small"
      hive.action_on_failure.should == "TERMINATE_JOB_FLOW"
      hive.log_uri.should == nil
    end

  end

  describe "#run" do

    it "should run the script with the specified variables and return the jobflow_id" do
      aws = Elasticity::EMR.new("", "")
      aws.should_receive(:run_job_flow).with({
        :name => "Elasticity Pig Job",
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
                "s3://elasticmapreduce/libs/pig/pig-script",
                  "--base-path",
                  "s3://elasticmapreduce/libs/pig/",
                  "--install-pig"
              ],
            },
            :name => "Setup Pig"
          },
            {
              :action_on_failure => "CONTINUE",
              :hadoop_jar_step => {
                :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
                :args => [
                  "s3://elasticmapreduce/libs/pig/pig-script",
                    "--run-pig-script",
                    "--args",
                    "-p", "OUTPUT=s3n://slif-pig-test/output",
                    "-p", "XREFS=s3n://slif-pig-test/xrefs",
                    "s3n://slif-pig-test/test.pig"
                ],
              },
              :name => "Run Pig Script"
            }
        ]
      }).and_return("new_jobflow_id")
      Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)

      pig = Elasticity::PigJob.new("access", "secret")
      pig.log_uri = "s3n://slif-test/output/logs"
      pig.action_on_failure = "CONTINUE"
      jobflow_id = pig.run('s3n://slif-pig-test/test.pig', {
        'OUTPUT' => 's3n://slif-pig-test/output',
        'XREFS' => 's3n://slif-pig-test/xrefs'
      })
      jobflow_id.should == "new_jobflow_id"
    end

  end

  describe "integration happy path" do
    use_vcr_cassette "pig_job/apache_log_reports", :record => :none
    it "should kick off the sample Amazion EMR Pig application" do
      pig = Elasticity::PigJob.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
      pig.log_uri = "s3n://slif-elasticity/pig-apache/logs"
      pig.ec2_key_name = "sharethrough_dev"
      jobflow_id = pig.run("s3n://elasticmapreduce/samples/pig-apache/do-reports.pig", {
        "INPUT"  => "s3n://elasticmapreduce/samples/pig-apache/input",
        "OUTPUT" => "s3n://slif-elasticity/pig-apache/output/2011-05-04"
      })
      jobflow_id.should == "j-16PZ24OED71C6"
    end
  end

end