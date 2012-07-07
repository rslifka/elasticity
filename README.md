Elasticity provides programmatic access to Amazon's Elastic Map Reduce service.  The aim is to conveniently map the EMR REST API calls to higher level operations that make working with job flows more productive and more enjoyable.

[![Build Status](https://secure.travis-ci.org/rslifka/elasticity.png)](http://travis-ci.org/rslifka/elasticity) REE, 1.8.7, 1.9.2, 1.9.3

Elasticity provides two ways to access EMR:

* **Indirectly through a JobFlow-based API**. This README discusses the Elasticity API.
* **Directly through access to the EMR REST API**. The less-discussed hidden darkside... I use this to enable the Elasticity API though it is not documented save for RubyDoc available at the the RubyGems [auto-generated documentation site](http://rubydoc.info/gems/elasticity/frames).  Be forewarned: Making the calls directly requires that you understand how to structure EMR requests at the Amazon API level and from experience I can tell you there are more fun things you could be doing :)  Scroll to the end for more information on the Amazon API. 

# Installation

```
  gem install elasticity
```

or in your Gemfile

```
  gem 'elasticity', '~> 2.0'
```

This will ensure that you protect yourself from API changes, which will only be made in major revisions.

# Kicking Off a Job

When using the EMR UI, there are several sample jobs that Amazon supplies.  The assets for these sample jobs are hosted on S3 and publicly available meaning you can run this code as-is (supplying your AWS credentials appropriately) and ```JobFlow#run``` will return the ID of the job flow.

```
require 'elasticity'

# Create a job flow with your AWS credentials
jobflow = Elasticity::JobFlow.new('AWS access key', 'AWS secret key')

# This is the first step in the jobflow - running a custom jar
step = Elasticity::CustomJarStep.new('s3n://elasticmapreduce/samples/cloudburst/cloudburst.jar')

# Here are the arguments to pass to the jar
c.arguments = %w(s3n://elasticmapreduce/samples/cloudburst/input/s_suis.br s3n://elasticmapreduce/samples/cloudburst/input/100k.br s3n://slif-output/cloudburst/output/2012-06-22 36 3 0 1 240 48 24 24 128 16)

# Add the step to the jobflow
jobflow.add_step(step)

# Let's go!
jobflow.run
```

Note that this example is only for ```CustomJarStep```.  ```PigStep``` and ```HiveStep``` will have different means of passing parameters.

# Working with Job Flows

Job flows are the center of the EMR universe.  The general order of operations is:

  1. Create a job flow.
  1. Specify options.
  1. (optional) Configure instance groups.
  1. (optional) Add bootstrap actions.
  1. Create steps.
  1. Run the job flow.
  1. (optional) Add additional steps.
  1. (optional) Shutdown the job flow.

## 1 - Creating Job Flows

Only your AWS credentials are needed.

```
jobflow = Elasticity::JobFlow.new('AWS access key', 'AWS secret key')
```

## 2 - Specifying Job Flow Options

Configuration job flow options, shown below with default values.  Note that these defaults are subject to change - they are reasonable defaults at the time(s) I work on them (e.g. the latest version of Hadoop).

These options are sent up as part of job flow submission (i.e. ```JobFlow#run```), so be sure to configure these before running the job.

```
jobflow.action_on_failure                 = 'TERMINATE_JOB_FLOW'
jobflow.ami_version                       = 'latest'
jobflow.ec2_key_name                      = 'default'
jobflow.ec2_subnet_id                     = nil
jobflow.hadoop_version                    = '0.20.205'
jobflow.keep_job_flow_alive_when_no_steps = true
jobflow.log_uri                           = nil
jobflow.name                              = 'Elasticity Job Flow'
jobflow.instance_count                    = 2
jobflow.master_instance_type              = 'm1.small'
jobflow.slave_instance_type               = 'm1.small'
```

## 3 - Configuring Instance Groups (optional)

Technically this is optional since Elasticity creates MASTER and CORE instance groups for you (one m1.small instance in each).  If you'd like your jobs to finish in an appreciable amount of time, you'll want to at least add a few instances to the CORE group :)

### The Easy Way™

If all you'd like to do is change the type or number of instances, ```JobFlow``` provides a few shortcuts to do just that.

```
jobflow.instance_count       = 10
jobflow.master_instance_type = 'm1.small'
jobflow.slave_instance_type  = 'c1.medium'
```

This says "I want 10 instances from EMR: one m1.small MASTER instance and nine c1.medium CORE instances."

### The Still-Easy Way™

Elasticity supports all EMR instance group types and all configuration options. The MASTER, CORE and TASK instance groups can be configured via ```JobFlow#set_master_instance_group```, ```JobFlow#set_core_instance_group``` and ```JobFlow#set_task_instance_group``` respectively.

#### On-Demand Instance Groups

These instances will be available for the life of your EMR job, versus Spot instances which are transient depending on your bid price (see below).

```
ig = Elasticity::InstanceGroup.new
ig.count = 10                       # Provision 10 instances
ig.type  = 'c1.medium'              # See the EMR docs for a list of supported types
ig.set_on_demand_instances          # This is the default setting


jobflow.set_core_instance_group(ig)
```

#### Spot Instance Groups

*When Amazon EC2 has unused capacity, it offers EC2 instances at a reduced cost, called the Spot Price. This price fluctuates based on availability and demand. You can purchase Spot Instances by placing a request that includes the highest bid price you are willing to pay for those instances. When the Spot Price is below your bid price, your Spot Instances are launched and you are billed the Spot Price. If the Spot Price rises above your bid price, Amazon EC2 terminates your Spot Instances.* - [EMR Developer Guide](http://docs.amazonwebservices.com/ElasticMapReduce/latest/DeveloperGuide/UsingEMR_SpotInstances.html)

```
ig = Elasticity::InstanceGroup.new
ig.count = 10                       # Provision 10 instances
ig.type  = 'c1.medium'              # See the EMR docs for a list of supported types
ig.set_spot_instances(0.25)         # Makes this a SPOT group with a $0.25 bid price


jobflow.set_core_instance_group(ig)
```

## 4 - Adding Bootstrap Actions (optional)

Bootstrap actions are run as part of setting up the job flow, so be sure to configure these before running the job.

```
[
  Elasticity::HadoopBootstrapAction.new('-m', 'mapred.map.tasks=101'),
  Elasticity::HadoopBootstrapAction.new('-m', 'mapred.reduce.child.java.opts=-Xmx200m')
  Elasticity::HadoopBootstrapAction.new('-m', 'mapred.tasktracker.map.tasks.maximum=14')
].each do |action|
  jobflow.add_bootstrap_action(action)
end
```

## 5 - Adding Steps

Each type of step has a default name that can be overridden (the :name field).  Apart from that, steps are configured differently - exhaustively described below.

### Adding a Pig Step

```
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

```
  s3://elasticmapreduce/libs/pig/pig-script
    --run-pig-script
      --args
        -p INPUT=s3n://elasticmapreduce/samples/pig-apache/input
        -p OUTPUT=s3n://slif-elasticity/pig-apache/output/2011-05-04
        -p E_PARALLELS=26
    s3n://elasticmapreduce/samples/pig-apache/do-reports.pig
```

Use this as you would any other Pig variable.

```
  A = LOAD 'myfile' AS (t, u, v);
  B = GROUP A BY t PARALLEL $E_PARALLELS;
  ...
```

### Adding a Hive Step

```
# Path to the Hive Script
hive_step = Elasticity::HiveStep.new('s3n://mybucket/script.hql')

# (optional) These variables are available during the execution of your script
hive_step.variables = {
  'VAR1' => 'VALUE1',
  'VAR2' => 'VALUE2'
}

jobflow.add_step(hive_step)
```

### Adding a Custom Jar Step

```
# Path to your jar
jar_step = Elasticity::CustomJarStep.new('s3n://mybucket/my.jar')

# (optional) Arguments passed to the jar
jar_step.arguments = ['arg1', 'arg2']

jobflow.add_step(jar_step)
```

## 6 - Running the Job Flow

Submit the job flow to Amazon, storing the ID of the running job flow.

```
jobflow_id = jobflow.run
```

## 7 - Adding Additional Steps (optional)

Steps can be added to a running jobflow just by calling ```#add_step``` on the job flow exactly how you add them prior to submitting the job.

## 8 - Shutting Down the Job Flow (optional)

By default, job flows are set to terminate when there are no more running steps.  You can tell the job flow to stay alive when it has nothing left to do:

```
jobflow.keep_job_flow_alive_when_no_steps = true
```

If that's the case, or if you'd just like to terminate a running jobflow before waiting for it to finish:

```
jobflow.shutdown
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
* Thanks to the following people who have contributed patches or helpful suggestions: [Ryan Weald](https://github.com/rweald), [Aram Price](https://github.com/aramprice/), [Wouter Broekhof](https://github.com/wouter/) and [Menno van der Sman](https://github.com/menno)


# License

```
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
```
