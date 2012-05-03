require 'spec_helper'

describe Elasticity::HiveJob do

  subject do
    Elasticity::HiveJob.new("access", "secret", "script")
  end

  it { should be_a_kind_of Elasticity::SimpleJob }

  its(:script)    { should == "script" }
  its(:variables) { should == {} }

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
                    "-d", "OUTPUT=s3n://slif-test/output"
                ],
              },
              :name => "Run Hive Script"
            }
        ]
      }).and_return("new_jobflow_id")
      Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)

      hive = Elasticity::HiveJob.new("access", "secret", "s3n://slif-hive/test.q")
      hive.log_uri = "s3n://slif-test/output/logs"
      hive.action_on_failure = "CONTINUE"
      hive.variables = {
        'OUTPUT' => 's3n://slif-test/output'
      }
      jobflow_id = hive.run
      jobflow_id.should == "new_jobflow_id"
    end

  end

  describe "integration happy path" do
    use_vcr_cassette "hive_job/hive_ads", :record => :none
    it "should kick off the sample Amazion EMR Hive application" do
      hive = Elasticity::HiveJob.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY, "s3n://elasticmapreduce/samples/hive-ads/libs/model-build.q")
      hive.ec2_key_name = "sharethrough_dev"
      jobflow_id = hive.run
      jobflow_id.should == "j-2I4HV6S3SDGD9"
    end
  end

end