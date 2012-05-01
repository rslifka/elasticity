require 'spec_helper'

describe Elasticity::PigJob do

  let(:pig_job) { Elasticity::PigJob.new("access", "secret", "script") }

  describe ".new" do
    it "should have good defaults" do
      pig_job.aws_access_key_id.should == "access"
      pig_job.aws_secret_access_key.should == "secret"
      pig_job.ec2_key_name.should == "default"
      pig_job.hadoop_version.should == "0.20"
      pig_job.instance_count.should == 2
      pig_job.master_instance_type.should == "m1.small"
      pig_job.name.should == "Elasticity Pig Job"
      pig_job.slave_instance_type.should == "m1.small"
      pig_job.action_on_failure.should == "TERMINATE_JOB_FLOW"
      pig_job.log_uri.should == nil
      pig_job.script.should == "script"
      pig_job.parallels.should == 1
    end
  end

  describe "#instance_count=" do
    it "should not allow instances to be set less than 2" do
      expect {
        pig_job.instance_count = 1
      }.to raise_error(ArgumentError, "Instance count cannot be set to less than 2 (requested 1)")
    end

    it "should recalculate @parallels" do
      expect {
        pig_job.instance_count = 10
      }.to change(pig_job, :parallels)
    end
  end

  describe "#slave_instance_type=" do
    it "should recalculate @parallels" do
      expect {
        pig_job.slave_instance_type = "c1.xlarge"
      }.to change(pig_job, :parallels)
    end
  end

  describe "calculated value of parallels" do

    before do
      pig_job.instance_count = 8
    end

    context "when slave is m1.small" do
      it "should be 7" do
        pig_job.slave_instance_type = "m1.small"
        pig_job.parallels.should == 7
      end
    end

    context "when slave is m1.large" do
      it "should be 13" do
        pig_job.slave_instance_type = "m1.large"
        pig_job.parallels.should == 13
      end
    end

    context "when slave is c1.medium" do
      it "should be 13" do
        pig_job.slave_instance_type = "c1.medium"
        pig_job.parallels.should == 13
      end
    end

    context "when slave is m1.xlarge" do
      it "should be 26" do
        pig_job.slave_instance_type = "m1.xlarge"
        pig_job.parallels.should == 26
      end
    end

    context "when slave is c1.xlarge" do
      it "should be 26" do
        pig_job.slave_instance_type = "c1.xlarge"
        pig_job.parallels.should == 26
      end
    end

    context "when slave is any other type" do
      it "should be 1" do
        pig_job.slave_instance_type = "foo"
        pig_job.parallels.should == 7
      end
    end

  end

  describe "#run" do

    context "when no bootstrap actions are specified" do

      it "should run the script with the specified variables and return the jobflow_id" do
        aws = Elasticity::EMR.new("", "")
        aws.should_receive(:run_job_flow).with({
          :name => "Elasticity Pig Job",
          :log_uri => "s3n://slif-test/output/logs",
          :instances => {
            :ec2_key_name => "default",
            :hadoop_version => "0.20",
            :instance_count => 8,
            :master_instance_type => "m1.small",
            :slave_instance_type => "m1.xlarge",
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
                      "-p", "E_PARALLELS=26",
                      "s3n://slif-pig-test/test.pig"
                  ],
                },
                :name => "Run Pig Script"
              }
          ]
        }).and_return("new_jobflow_id")

        Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)
        pig = Elasticity::PigJob.new("access", "secret", "s3n://slif-pig-test/test.pig")

        pig.log_uri = "s3n://slif-test/output/logs"
        pig.action_on_failure = "CONTINUE"
        pig.instance_count = 8
        pig.slave_instance_type = "m1.xlarge"
        pig.variables = {
          'OUTPUT' => 's3n://slif-pig-test/output',
          'XREFS' => 's3n://slif-pig-test/xrefs'
        }
        jobflow_id = pig.run
        jobflow_id.should == "new_jobflow_id"
      end
    end

    context "when bootstrap actions are specified" do
      it "should run the script wth the proper job configuration" do
        aws = Elasticity::EMR.new("", "")
        aws.should_receive(:run_job_flow).with(hash_including({
          :bootstrap_actions => [
            {
              :name => "Elasticity Bootstrap Action (Configure Hadoop)",
              :script_bootstrap_action => {
                :path => "s3n://elasticmapreduce/bootstrap-actions/configure-hadoop",
                :args => ["-m", "foo=111"]
              }
            },
              {
                :name => "Elasticity Bootstrap Action (Configure Hadoop)",
                :script_bootstrap_action => {
                  :path => "s3n://elasticmapreduce/bootstrap-actions/configure-hadoop",
                  :args => ["-m", "bar=222"]
                }
              }
          ],
        }))

        Elasticity::EMR.should_receive(:new).with("access", "secret").and_return(aws)
        pig = Elasticity::PigJob.new("access", "secret", "s3n://slif-pig-test/test.pig")
        pig.add_hadoop_bootstrap_action("-m", "foo=111")
        pig.add_hadoop_bootstrap_action("-m", "bar=222")
        pig.run
      end
    end

  end

  describe "integration happy path" do

    context "with bootstrap actions" do
      use_vcr_cassette "pig_job/apache_log_reports_with_bootstrap", :record => :none
      it "should kick off the sample Amazion EMR Pig application" do
        pig = Elasticity::PigJob.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY, "s3n://elasticmapreduce/samples/pig-apache/do-reports.pig")
        pig.ec2_key_name = "sharethrough_dev"
        pig.add_hadoop_bootstrap_action("-m", "mapred.job.reuse.jvm.num.tasks=120")
        pig.variables = {
          "INPUT" => "s3n://elasticmapreduce/samples/pig-apache/input",
          "OUTPUT" => "s3n://slif-elasticity/pig-apache/output/2011-05-10"
        }
        jobflow_id = pig.run
        jobflow_id.should == "j-1UK43AWRT3QHD"
      end
    end

    context "without bootstrap actions" do
      use_vcr_cassette "pig_job/apache_log_reports", :record => :none
      it "should kick off the sample Amazion EMR Pig application" do
        pig = Elasticity::PigJob.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY, "s3n://elasticmapreduce/samples/pig-apache/do-reports.pig")
        pig.log_uri = "s3n://slif-elasticity/pig-apache/logs"
        pig.ec2_key_name = "sharethrough_dev"
        pig.variables = {
          "INPUT" => "s3n://elasticmapreduce/samples/pig-apache/input",
          "OUTPUT" => "s3n://slif-elasticity/pig-apache/output/2011-05-04"
        }
        jobflow_id = pig.run
        jobflow_id.should == "j-1HB7A3TBRT3VS"
      end
    end
  end

end