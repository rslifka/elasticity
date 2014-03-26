[![Gem Version](https://badge.fury.io/rb/elasticity.png)](http://badge.fury.io/rb/elasticity)

**(March 26, 2014)** Taking requests! I have a few ideas for what might be cool features though I'd rather work on what the community wants.  Go ahead and file an issue!

Elasticity provides programmatic access to Amazon's Elastic Map Reduce service.  The aim is to conveniently abstract away the complex EMR REST API and make working with job flows more productive and more enjoyable.

[![Build Status](https://secure.travis-ci.org/rslifka/elasticity.png)](http://travis-ci.org/rslifka/elasticity) 1.9.3, 2.0.0, 2.1.0, 2.1.1

Elasticity provides two ways to access EMR:

* **Indirectly through a JobFlow-based API**. This README discusses the Elasticity API.
* **Directly through access to the EMR REST API**. The less-discussed hidden darkside... I use this to enable the Elasticity API.  RubyDoc can be found at the RubyGems [auto-generated documentation site](http://rubydoc.info/gems/elasticity/frames).  Be forewarned: Making the calls directly requires that you understand how to structure EMR requests at the Amazon API level and from experience I can tell you there are more fun things you could be doing :)  Scroll to the end for more information on the Amazon API.

# Installation

```
gem install elasticity
```

or in your Gemfile

```
gem 'elasticity', '~> 3.0'
```

This will ensure that you protect yourself from API changes, which will only be made in major revisions.

# Roughly, What Am I Getting Myself Into?

If you're familiar with the AWS EMR UI, you'll recall there are sample jobs Amazon supplies to help us get familiar with EMR.  Here's how you'd kick off the "Cloudburst (Custom Jar)" sample job with Elasticity.  You can run this code as-is (supplying your AWS credentials and an output location) and ```JobFlow#run``` will return the ID of the job flow.

```ruby
require 'elasticity'

# Create a job flow with your AWS credentials
jobflow = Elasticity::JobFlow.new('AWS access key', 'AWS secret key')

# Omit credentials to use the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
# jobflow = Elasticity::JobFlow.new

# NOTE: Amazon requires that all new accounts specify a VPC subnet when launching jobs.
# If you're on an existing account, this is unnecessary however new AWS accounts require
# subnet IDs be specified when launching jobs.
# jobflow.ec2_subnet_id = 'YOUR_SUBNET_ID_HERE'

# This is the first step in the jobflow - running a custom jar
step = Elasticity::CustomJarStep.new('s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar')

# Here are the arguments to pass to the jar
step.arguments = %w(s3n://elasticmapreduce/samples/cloudburst/input/s_suis.br s3n://elasticmapreduce/samples/cloudburst/input/100k.br s3n://OUTPUT_BUCKET/cloudburst/output/2012-06-22 36 3 0 1 240 48 24 24 128 16)

# Add the step to the jobflow
jobflow.add_step(step)

# Let's go!
jobflow.run
```

Note that this example is only for ```CustomJarStep```.  Other steps will have different means of passing parameters.

# Working with Job Flows

Job flows are the center of the EMR universe.  The general order of operations is:

  1. Create a job flow.
  1. Specify options.
  1. (optional) Configure instance groups.
  1. (optional) Add bootstrap actions.
  1. (optional) Add steps.
  1. (optional) Upload assets.
  1. Run the job flow.
  1. (optional) Add additional steps.
  1. (optional) Wait for the job flow to complete.
  1. (optional) Shutdown the job flow.

## 1 - Create a Job Flow

Only your AWS credentials are needed.

```ruby
# Manually specify AWS credentials
jobflow = Elasticity::JobFlow.new('AWS access key', 'AWS secret key')

# Use the standard environment variables (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
jobflow = Elasticity::JobFlow.new
```

If you want to access a job flow that's already running:

```ruby
# Manually specify AWS credentials
jobflow = Elasticity::JobFlow.from_jobflow_id('AWS access key', 'AWS secret key', 'jobflow ID', 'region')

# Use the standard environment variables (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
jobflow = Elasticity::JobFlow.from_jobflow_id(nil, nil, 'jobflow ID', 'region')
```

This is useful if you'd like to attach to a running job flow and add more steps, etc.  The ```region``` parameter is necessary because job flows are only accessible from the the API when you connect to the same endpoint that created them (e.g. us-west-1).  If you don't specify the ```region``` parameter, us-east-1 is assumed.

## 2 - Specifying Options

Configuration job flow options, shown below with default values.  Note that these defaults are subject to change - they are reasonable defaults at the time(s) I work on them (e.g. the latest version of Hadoop).

These options are sent up as part of job flow submission (i.e. ```JobFlow#run```), so be sure to configure these before running the job.

```ruby
jobflow.name                              = 'Elasticity Job Flow'

jobflow.action_on_failure                 = 'TERMINATE_JOB_FLOW'
jobflow.keep_job_flow_alive_when_no_steps = false
jobflow.ami_version                       = 'latest'
jobflow.hadoop_version                    = '1.0.3'
jobflow.log_uri                           = nil
jobflow.enable_debugging                  = false # Requires a log_uri to enable

jobflow.ec2_key_name                      = nil
jobflow.ec2_subnet_id                     = nil
jobflow.visible_to_all_users              = false
jobflow.placement                         = 'us-east-1a'
jobflow.instance_count                    = 2
jobflow.master_instance_type              = 'm1.small'
jobflow.slave_instance_type               = 'm1.small'
```

## 3 - Configure Instance Groups (optional)

Technically this is optional since Elasticity creates MASTER and CORE instance groups for you (one m1.small instance in each).  If you'd like your jobs to finish in an appreciable amount of time, you'll want to at least add a few instances to the CORE group :)

### The Easy Way™

If all you'd like to do is change the type or number of instances, ```JobFlow``` provides a few shortcuts to do just that.

```ruby
jobflow.instance_count       = 10
jobflow.master_instance_type = 'm1.small'
jobflow.slave_instance_type  = 'c1.medium'
```

This says "I want 10 instances from EMR: one m1.small MASTER instance and nine c1.medium CORE instances."

### The Still-Easy Way™

Elasticity supports all EMR instance group types and all configuration options. The MASTER, CORE and TASK instance groups can be configured via ```JobFlow#set_master_instance_group```, ```JobFlow#set_core_instance_group``` and ```JobFlow#set_task_instance_group``` respectively.

#### On-Demand Instance Groups

These instances will be available for the life of your EMR job, versus Spot instances which are transient depending on your bid price (see below).

```ruby
ig = Elasticity::InstanceGroup.new
ig.count = 10                       # Provision 10 instances
ig.type  = 'c1.medium'              # See the EMR docs for a list of supported types
ig.set_on_demand_instances          # This is the default setting

jobflow.set_core_instance_group(ig)
```

#### Spot Instance Groups

*When Amazon EC2 has unused capacity, it offers EC2 instances at a reduced cost, called the Spot Price. This price fluctuates based on availability and demand. You can purchase Spot Instances by placing a request that includes the highest bid price you are willing to pay for those instances. When the Spot Price is below your bid price, your Spot Instances are launched and you are billed the Spot Price. If the Spot Price rises above your bid price, Amazon EC2 terminates your Spot Instances.* - [EMR Developer Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/UsingEMR_SpotInstances.html)

```ruby
ig = Elasticity::InstanceGroup.new
ig.count = 10                       # Provision 10 instances
ig.type  = 'c1.medium'              # See the EMR docs for a list of supported types
ig.set_spot_instances(0.25)         # Makes this a SPOT group with a $0.25 bid price

jobflow.set_core_instance_group(ig)
```

## 4 - Add Bootstrap Actions (optional)

Bootstrap actions are run as part of setting up the job flow, so be sure to configure these before running the job.

### Bootstrap Actions

With the basic ```BootstrapAction``` you specify everything about the action - the script, options and arguments.

```ruby
action = Elasticity::BootstrapAction.new('s3n://my-bucket/my-script', '-g', '100')
jobflow.add_bootstrap_action(action)
```

### Hadoop Bootstrap Actions

`HadoopBootstrapAction` handles passing Hadoop configuration options through.

```ruby
[
  Elasticity::HadoopBootstrapAction.new('-m', 'mapred.map.tasks=101'),
  Elasticity::HadoopBootstrapAction.new('-m', 'mapred.reduce.child.java.opts=-Xmx200m')
  Elasticity::HadoopBootstrapAction.new('-m', 'mapred.tasktracker.map.tasks.maximum=14')
].each do |action|
  jobflow.add_bootstrap_action(action)
end
```

### Hadoop File Bootstrap Actions

With EMR's current limit of 15 bootstrap actions, chances are you're going to create a configuration file full of your options and opt to use that instead of passing all the options individually.  In that case, use the ```HadoopFileBootstrapAction```, supplying the location of your configuration file.

```ruby
action = Elasticity::HadoopFileBootstrapAction.new('s3n://my-bucket/job-config.xml')
jobflow.add_bootstrap_action(action)
```

## 5 - Add Steps (optional)

Each type of step has ```#name``` and ```#action_on_failure``` fields that can be specified.  Apart from that, steps are configured differently - exhaustively described below.

### Adding a Pig Step

```ruby
# Path to the Pig script
pig_step = Elasticity::PigStep.new('s3n://mybucket/script.pig')

# (optional) These variables are available during the execution of your script
pig_step.variables = {
  'VAR1' => 'VALUE1',
  'VAR2' => 'VALUE2'
}

jobflow.add_step(pig_step)
```

#### PARALLEL

Given the importance of specifying a reasonable value for [the number of parallel reducers](http://pig.apache.org/docs/r0.8.1/cookbook.html#Use+the+Parallel+Features PARALLEL), Elasticity calculates and passes through a reasonable default up with every invocation in the form of a script variable called E_PARALLELS.  This default value is based off of the formula in the Pig Cookbook and the number of reducers AWS configures per instance.

For example, if you had 8 instances in total and your slaves were m1.xlarge, the value is 26 (as shown below).

```sh
  s3://elasticmapreduce/libs/pig/pig-script
    --run-pig-script
      --args
        -p INPUT=s3n://elasticmapreduce/samples/pig-apache/input
        -p OUTPUT=s3n://slif-elasticity/pig-apache/output/2011-05-04
        -p E_PARALLELS=26
    s3n://elasticmapreduce/samples/pig-apache/do-reports.pig
```

Use this as you would any other Pig variable.

```pig
  A = LOAD 'myfile' AS (t, u, v);
  B = GROUP A BY t PARALLEL $E_PARALLELS;
  ...
```

### Adding a Hive Step

```ruby
# Path to the Hive Script
hive_step = Elasticity::HiveStep.new('s3n://mybucket/script.hql')

# (optional) These variables are available during the execution of your script
hive_step.variables = {
  'VAR1' => 'VALUE1',
  'VAR2' => 'VALUE2'
}

jobflow.add_step(hive_step)
```

### Adding a Streaming Step

```ruby
# Input bucket, output bucket, mapper script,reducer script
streaming_step = Elasticity::StreamingStep.new('s3n://elasticmapreduce/samples/wordcount/input', 's3n://elasticityoutput/wordcount/output/2012-07-23', 's3n://elasticmapreduce/samples/wordcount/wordSplitter.py', 'aggregate')

# Optionally, include additional *arguments
# streaming_step = Elasticity::StreamingStep.new('s3n://elasticmapreduce/samples/wordcount/input', 's3n://elasticityoutput/wordcount/output/2012-07-23', 's3n://elasticmapreduce/samples/wordcount/wordSplitter.py', 'aggregate', '-arg1', 'value1')

jobflow.add_step(streaming_step)
```

### Adding a Custom Jar Step

```ruby
# Path to your jar
jar_step = Elasticity::CustomJarStep.new('s3n://mybucket/my.jar')

# (optional) Arguments passed to the jar
jar_step.arguments = ['arg1', 'arg2']

jobflow.add_step(jar_step)
```

### Adding a Script Step

```ruby
# Path to your script, plus arguments
script_step = Elasticity::ScriptStep.new('script_location', 'arg1', 'arg2')

jobflow.add_step(script_step)
```

### Adding an S3DistCp Step

For a complete list of supported arguments, please see the [Amazon EMR guide](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/UsingEMR_s3distcp.html).

```ruby
# Path to your script, plus arguments (both symbols and strings are supported)
copy_step = Elasticity::S3DistCpStep.new(:arg1 => 'value1', 'arg2' => 'value2')

jobflow.add_step(copy_step)
```

## 6 - Upload Assets (optional)

This isn't part of ```JobFlow```; more of an aside.  Elasticity provides a very basic means of uploading assets to S3 so that your EMR job has access to them.  Most commonly this will be a set of resources to run the job (e.g. JAR files, streaming scripts, etc.) and a set of resources used by the job itself (e.g. a TSV file with a range of valid values, join tables, etc.).

```ruby
# Specify the bucket name, AWS credentials and region
s3 = Elasticity::SyncToS3.new('my-bucket', 'access', 'secret', 'region')

# Alternatively, specify nothing :)
# - Use the standard environment variables (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
# - Use the 'us-east-1' region by default
# s3 = Elasticity::SyncToS3('my-bucket')

# Recursively sync the contents of '/foo' under the remote location 'remote-dir/this-job'
s3.sync('/foo', 'remote-dir/this-job')

# Sync a single file to a remote directory
s3.sync('/foo/this-job/tables/join.tsv', 'remote-dir/this-job/tables')
```

If the bucket doesn't exist, it will be created.

If a file already exists, there is an MD5 checksum evaluation.  If the checksums are the same, the file will be skipped.  Now you can use something like ```s3n://my-bucket/remote-dir/this-job/tables/join.tsv``` in your EMR jobs.

## 7 - Run the Job Flow

Submit the job flow to Amazon, storing the ID of the running job flow.

```ruby
jobflow_id = jobflow.run
```

## 8 - Add Additional Steps (optional)

Steps can be added to a running jobflow just by calling ```#add_step``` on the job flow exactly how you add them prior to submitting the job.

## 9 - Wait For the Job Flow to Complete (optional)

Elasticity has the ability to block until the status of a job flow is not STARTING or RUNNING.  There are two flavours.  Without a status callback:

```ruby
# Blocks until status changes
jobflow.wait_for_completion
```

And with a status callback, providing the elapsed time and an instance of ```Elasticity::JobFlowStatus``` so you can inspect the progress of the job.

```ruby
# Blocks until status changes, calling back every 60 seconds
jobflow.wait_for_completion do |elapsed_time, job_flow_status|
  puts "Waiting for #{elapsed_time}, jobflow status: #{job_flow_status.state}"
end
```

## 10 - Shut Down the Job Flow (optional)

By default, job flows are set to terminate when there are no more running steps.  You can tell the job flow to stay alive when it has nothing left to do:

```ruby
jobflow.keep_job_flow_alive_when_no_steps = true
```

If that's the case, or if you'd just like to terminate a running jobflow before waiting for it to finish:

```ruby
jobflow.shutdown
```

# Elasticity Configuration

Elasticity supports a wide range of configuration options :) all of which are shown below.

```ruby
Elasticity.configure do |config|

  # If using Hive, it will be configured via the directives here
  config.hive_site = 's3://bucket/hive-site.xml'

end
```

# Amazon EMR Documentation

Elasticity wraps all of the EMR API calls.  Please see the Amazon guide for details on these operations because the default values aren't obvious (e.g. the meaning of <code>DescribeJobFlows</code> without parameters).

You may opt for "direct" access to the API where you specify the params and Elasticity takes care of the signing for you, responding with the XML from Amazon.

In addition to the [AWS EMR site](http://aws.amazon.com/elasticmapreduce/), there are three primary resources of reference information for EMR:

* [Amazon EMR Getting Started Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/GettingStartedGuide/)
* [Amazon EMR Developer Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/)
* [Amazon EMR API Reference](http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/)

Unfortunately, the documentation is sometimes incorrect and sometimes missing.  E.g. the allowable values for ```AddInstanceGroups``` are present in the [PDF](http://awsdocs.s3.amazonaws.com/ElasticMapReduce/20090331/emr-api-20090331.pdf) version of the API reference but not in the [HTML](http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/) version.  Elasticity implements the API as specified in the PDF reference as that is the most complete description I could find.

# Thanks!

* AWS signing was used from [RightScale's](http://www.rightscale.com/) amazing [right_aws gem](https://github.com/rightscale/right_aws) which works extraordinarily well!  If you need access to any AWS service (EC2, S3, etc.), have a look.
* <code>camelize</code> was used from ActiveSupport to assist in converting parmeters to AWS request format.
* Thanks to [Ryan Weald](https://github.com/rweald) and [Alexander Dean](https://github.com/alexanderdean) for their constant barrage of excellent suggestions :)

# License

```
  Copyright 2011-2013 Robert Slifka

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
```
