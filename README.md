Elasticity provides programmatic access to Amazon's Elastic Map Reduce service.  The aim is to conveniently wrap the API operations in a manner that makes working with EMR job flows from Ruby more productive and more enjoyable, without having to understand the nuts and bolts of the EMR REST API.  At the very least, using Elasticity allows you to easily experiment with the EMR API :)

**CREDITS**: AWS signing was used from [RightScale's](http://www.rightscale.com/) amazing [right_aws gem](https://github.com/rightscale/right_aws) which works extraordinarily well!  If you need access to any AWS service (EC2, S3, etc.), have a look.  Used camelize from ActiveSupport as well, thank you \Rails :)

**CONTRIBUTIONS**:

+ [Wouter Broekhof](https://github.com/wouter/) - HTTPS and AWS region support, additional params to describe_jobflows.

# Installation and Usage

<pre>
  gem install elasticity
</pre>

All you have to do is <code>require 'elasticity'</code> and you're all set!

# Simplified API Reference

Elasticity currently provides simplified access to launching Hive, Pig and Custom Jar job flows, specifying several default values that you may optionally override:

<pre>
  @action_on_failure = "TERMINATE_JOB_FLOW"
  @ec2_key_name = "default"
  @hadoop_version = "0.20"
  @instance_count = 2
  @master_instance_type = "m1.small"
  @name = "Elasticity Job"
  @slave_instance_type = "m1.small"
</pre>

These are all accessible from the simplified jobs.  See the PigJob description for an example.

### Bootstrap Actions

You can also configure Hadoop options with add_hadoop_bootstrap_action().

<pre>
  pig = Elasticity::PigJob.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  pig.add_hadoop_bootstrap_action("-m", "mapred.job.reuse.jvm.num.tasks=120")
  ...
</pre>

## Hive

HiveJob allows you to quickly launch Hive jobs without having to understand the ins and outs of the EMR API.  Specify only the Hive script location and (optionally) variables to make available to the Hive script.

<pre>
  hive = Elasticity::HiveJob.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  hive.run("s3n://slif-hive/test.q", {
    "LIB"    => "s3n://slif-test/lib",
    "OUTPUT" => "s3n://slif-test/output"
  })
  
  > "j-129V5AQFMKO1C"
</pre>

## Pig

Like HiveJob, PigJob allows you to quickly launch Pig jobs :)

<pre>
  pig = Elasticity::PigJob.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  pig.log_uri = "s3n://slif-elasticity/pig-apache/logs"
  pig.ec2_key_name = "slif_dev"
  pig.run("s3n://elasticmapreduce/samples/pig-apache/do-reports.pig", {
    "INPUT"  => "s3n://elasticmapreduce/samples/pig-apache/input",
    "OUTPUT" => "s3n://slif-elasticity/pig-apache/output/2011-05-04"
  })
  
  > "j-16PZ24OED71C6"
</pre>

### PARALLEL

Given the importance of specifying a reasonable value for [the number of parallel reducers](http://pig.apache.org/docs/r0.8.1/cookbook.html#Use+the+Parallel+Features PARALLEL), Elasticity calculates and passes through a reasonable default up with every invocation in the form of a script variable called E_PARALLELS.  This default value is based off of the formula in the Pig Cookbook and the number of reducers AWS configures per instance.

For example, if you had 8 instances in total and your slaves were m1.xlarge, the value is 26 (as shown below).

<pre>
  s3://elasticmapreduce/libs/pig/pig-script
    --run-pig-script
      --args
        -p INPUT=s3n://elasticmapreduce/samples/pig-apache/input
        -p OUTPUT=s3n://slif-elasticity/pig-apache/output/2011-05-04
        -p E_PARALLELS=26
    s3n://elasticmapreduce/samples/pig-apache/do-reports.pig
</pre>

Use this as you would any other Pig variable.

<pre>
  A = LOAD 'myfile' AS (t, u, v);
  B = GROUP A BY t PARALLEL $E_PARALLELS;
  ...
</pre>

## Custom Jar

Custom jar jobs are also available.  To kick off a custom job, specify the path to the jar and any arguments you'd like passed to the jar.

<pre>
  custom_jar = Elasticity::PigJob.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  custom_jar.log_uri = "s3n://slif-test/output/logs"
  custom_jar.action_on_failure = "TERMINATE_JOB_FLOW"
  jobflow_id = custom_jar.run('s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar', [
      "s3n://elasticmapreduce/samples/cloudburst/input/s_suis.br",
      "s3n://elasticmapreduce/samples/cloudburst/input/100k.br",
      "s3n://slif_hadoop_test/cloudburst/output/2011-12-09",
  ])
  
  > "j-1IU6NM8OUPS9I"
</pre>

# Amazon API Reference

Elasticity wraps all of the EMR API calls.  Please see the Amazon guide for details on these operations because the default values aren't obvious (e.g. the meaning of <code>DescribeJobFlows</code> without parameters).

You may opt for "direct" access to the API where you specify the params and Elasticity takes care of the signing for you, responding with the XML from Amazon.  Direct access is described below the API catalog.

In addition to the [AWS EMR subsite](http://aws.amazon.com/elasticmapreduce/), there are three primary resources of reference information for EMR:

* [Amazon EMR Getting Started Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/GettingStartedGuide/)
* [Amazon EMR Developer Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/)
* [Amazon EMR API Reference](http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/)

Unfortunately, the documentation is sometimes incorrect and sometimes missing.  E.g. the allowable values for AddInstanceGroups are present in the [PDF](http://awsdocs.s3.amazonaws.com/ElasticMapReduce/20090331/emr-api-20090331.pdf) version of the API reference but not in the [HTML](http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/) version.  Elasticity implements the API as specified in the PDF reference as that is the most complete description I could find.

## AddInstanceGroups

AddInstanceGroups adds a group of instances to an existing job flow.  The available instance configuration options are listed in the EMR API reference.  They've been converted to be more Ruby-like in the wrappers, as shown in the example below.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  instance_group_config = {
    :instance_count => 1,
    :instance_role => "TASK",
    :instance_type => "m1.small",
    :market => "ON_DEMAND",
    :name => "Go Canucks Go!"
  }
  emr.add_instance_groups("j-26LIXPUNSC0M3", [instance_group_config])
  
  > ["ig-E7C8MGA2ULQ1"]
</pre>

Some combinations of the options will be rejected by Amazon and some once-valid options will sometimes be rejected if they not relevant to the current state of the job flow (e.g. duplicate addition of TASK groups to the same job flow).

<pre>
  emr.add_instance_groups("j-26LIXPUNSC0M3", [instance_group_config])
  
  > Task instance group already exists in the job flow, cannot add more task groups
</pre>

## AddJobFlowSteps

AddJobFlowSteps adds the specified steps to the specified job flow.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  jobflow_id = emr.run_job_flow(...)
  emr.add_jobflow_steps(jobflow_id, {
    :steps => [
      {
        :action_on_failure => "TERMINATE_JOB_FLOW",
        :hadoop_jar_step => {
          :args => [
            "s3://elasticmapreduce/libs/pig/pig-script",
            "--base-path",
            "s3://elasticmapreduce/libs/pig/",
            "--install-pig"
          ],
          :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
        },
        :name => "Setup Pig"
      }
    ]
  })
</pre>

## describe_jobflow (Elasticity Convenience Method)

This is a convenience methods that wraps DescribeJobFlow to return the status of a single job.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  jobflow = emr.describe_jobflow("j-129V5AQFMKO1C")
  p jobflow.jobflow_id
  > "j-129V5AQFMKO1C"
  p jobflow.name
  > "Elasticity Test Job"
</pre>

## DescribeJobFlows

DescribeJobFlows returns detailed information as to the state of all jobs.  Currently this is wrapped in an <code>Elasticity::JobFlow</code> that contains the <code>name</code>, <code>jobflow_id</code> and <code>state</code>.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  jobflows = emr.describe_jobflows
  p jobflows.map(&:name)

  > ["Hive Test", "Pig Test", "Interactive Hadoop", "Interactive Hive"]
</pre>

## ModifyInstanceGroups

A job flow contains several "instance groups" of various types.  These instances are where the work for your EMR task occurs.  After a job flow has been created, you can find these instance groups in the AWS web UI by clicking on a job flow and then clicking on the "Instance Groups" tab.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.modify_instance_groups({"ig-2T1HNUO61BG3O" => 3})
</pre>

If there's an error, you'll receive an ArgumentError containing the message from Amazon.  For example if you attempt to modify an instance group that's part of a terminated job flow:

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.modify_instance_groups({"ig-some_terminated_group" => 3})
  
  > ArgumentError: An instance group may only be modified when the job flow is running or waiting
</pre>

Or if you attempt to increase the instance count of the MASTER instance group:

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.modify_instance_groups({"ig-some_terminated_group" => 3})
  
  > ArgumentError: A master instance group may not be modified
</pre>

## RunJobFlow

RunJobFlow creates and starts a new job flow.  Specifying the arguments to RunJobFlow is a bit of a hot mess at the moment, requiring you to understand the EMR syntax as well as the data structure for specifying jobs.  Here's a beefy example:

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  jobflow_id = emr.run_job_flow({
    :name => "Elasticity Test Flow (EMR Pig Script)",
    :instances => {
      :ec2_key_name => "sharethrough-dev",
      :hadoop_version => "0.20",
      :instance_count => 2,
      :master_instance_type => "m1.small",
      :placement => {
        :availability_zone => "us-east-1a"
      },
      :slave_instance_type => "m1.small",
    },
    :steps => [
      {
        :action_on_failure => "TERMINATE_JOB_FLOW",
        :hadoop_jar_step => {
          :args => [
            "s3://elasticmapreduce/libs/pig/pig-script",
            "--base-path",
            "s3://elasticmapreduce/libs/pig/",
            "--install-pig"
          ],
          :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
        },
        :name => "Setup Pig"
      },
        {
          :action_on_failure => "TERMINATE_JOB_FLOW",
          :hadoop_jar_step => {
            :args => [
              "s3://elasticmapreduce/libs/pig/pig-script",
              "--run-pig-script",
              "--args",
              "-p",
              "INPUT=s3n://elasticmapreduce/samples/pig-apache/input",
              "-p",
              "OUTPUT=s3n://slif-elasticity/pig-apache/output/2011-04-19",
              "s3n://elasticmapreduce/samples/pig-apache/do-reports.pig"
            ],
            :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
          },
          :name => "Run Pig Script"
        }
    ]
  })

  > "j-129V5AQFMKO1C"
</pre>

Currently Elasticity doesn't do much to ease this pain although this is what I would like to focus on in coming releases.  Feel free to ship ideas my way.  In the meantime, have a look at the EMR API [PDF](http://awsdocs.s3.amazonaws.com/ElasticMapReduce/20090331/emr-api-20090331.pdf) under the RunJobFlow action and riff off of the example here.

## SetTerminationProtection

Enable or disable "termination protection" on the specified job flows.  Termination protection prevents a job flow from from being terminated by any user-initiated action.  

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.set_termination_protection(["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5"])
</pre>

To disable termination protection, specify false as the second parameter.

<pre>
  emr.set_termination_protection(["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5"], false)
</pre>

## TerminateJobFlows

Terminate the specified job flow.  When the job flow '''exists''', you will receive no output.  This is because Amazon does not return anything other than a 200 when you terminate a job flow :)  You'll want to continuously poll with DescribeJobFlows to see when the job was actually terminated.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.terminate_jobflows("j-BOWBV7884XD0")
</pre>

When the job flow '''doesn't exist''':

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.terminate_jobflows("no-flow")
  
  > ArgumentError: Job flow 'no-flow' does not exist.
</pre>

# Direct Response Access

If you're fine with Elasticity's invocation wrapping and would prefer to get at the resulting XML rather than the wrapped response, throw a block our way and we'll yield the result.  This still saves you the trouble of having to create the params and sign the request yet gives you direct access to the response XML for your parsing pleasure.

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  emr.describe_jobflows{|xml| puts xml[0..77]}
  
  > &lt;DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/200...
</pre>

# Direct Request/Response Access

If you're chomping at the bit to initiate some EMR functionality that isn't wrapped (or isn't wrapped in a way you prefer :) feel free to access the AWS EMR API directly by using <code>EMR.direct()</code>.  You can find the allowed values in Amazon's EMR API [developer documentation](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/index.html).

<pre>
  emr = Elasticity::EMR.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_KEY"])
  params = {"Operation" => "DescribeJobFlows"}
  result_xml = emr.direct(params)
  result_xml[0..78]
  
  > &lt;DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009...
</pre>

# License

<pre>
  Copyright 2011-2012 Robert Slifka

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
</pre>

### Development Notes for Slif

[Versioning Guide](http://docs.rubygems.org/read/chapter/7#page27), c/o [@brokenladder](https://twitter.com/#!/brokenladder)

<pre>
  rake build    # Build lorem-0.0.2.gem into the pkg directory
  rake install  # Build and install lorem-0.0.2.gem into system gems
  rake release  # Create tag v0.0.2 and build
                # and push lorem-0.0.2.gem to Rubygems
</pre>
