### 2.0 - In Progress

2.0 is a rewrite of the "simplified" API after nearly a year's worth of daily use at [Sharethrough](http://www.sharethrough.com/) and a recent doubling-down on our EMR infrastructure.  In order to more quickly support some really interesting features like a command-line interface, persistent clusters, Hbase, etc. - a remodeling of the simplified API was done.  Unfortunately, this is going to result in breaking changes to the API, hence the bump to 2.0.  I hope that most of you are using ```gem 'elasticity', '~> 1.5'``` :) 

+ The ```SimpleJob``` API has been removed in favour of a more modular 'step'-based approach using the "JobFlow" and "Step" vernacular, in line with Amazon's own communication.  If you understand the AWS Web UI, using Elasticity should be a bit more straightforward.
+ ```JobFlow``` and ```JobFlowStep``` are now ```JobFlowStatus``` and ```JobFlowStatusStep``` respectively, allowing the creation of ```JobFlow``` and ```JobFlowStep``` to be used in job submission.
+ Bumped the default Hadoop version to 0.20.205.
+ Now possible to specify the AMI version.
+ Now possible to specify keep alive clusters.
+ Now possible to specify an EC2 subnet ID (VPC).
+ Hadoop bootstrap actions can now be named.
+ Development dependency updates: ruby-1.9.3-p194, rspec-2.10.

### 1.5

+ Added support for Hadoop bootstrap actions to all job types (Pig, Hive and Custom Jar).
+ Added support for REE 1.8.7-2011.12, Ruby 1.9.2 and 1.9.3.
+ Updated to the latest versions of all development dependencies (notably VCR 2).

### 1.4.1

+ Added ```Elasticity::EMR#describe_jobflow("jobflow_id")``` for describing a specific job.  If you happen to run hundreds of EMR jobs, this makes retrieving jobflow status much faster than using ```Elasticity::EMR#describe_jobflowS``` which pulls down and parses XML status for hundreds of jobs.

### 1.4

+ Added ```Elasticity::CustomJarJob``` for launching "Custom Jar" jobs.

### 1.3.1

+ Explicitly requiring 'time' (only a problem if you aren't running from within a Rails environment).
+ ```Elasticity::JobFlow``` now exposes ```last_state_change_reason```.

### 1.3 (Contributions from Wouter Broekhof)

+ The default mode of communication is now via HTTPS.
+ ```Elasticity::AwsRequest``` new option ```:secure => true|false``` (whether to use HTTPS).
+ ```Elasticity::AwsRequest``` new option ```:region => eu-west-1|...``` (which region to run the EMR job).
+ ```Elasticity::EMR#describe_jobflows``` now accepts additional params for filtering the jobflow query (see docs).

### 1.2.2

+ ```HiveJob``` and ```PigJob``` now support configuring Hadoop options via ```#add_hadoop_bootstrap_action()```.

### 1.2.1

+ Shipping up E_PARALLELS Pig variable with each invocation; reasonable default value for PARALLEL based on the number and type of instances configured.

### 1.2

+ Added ```PigJob```!

### 1.1.1

+ ```HiveJob``` critical bug fixed, now it works :)
+ Added ```log_uri``` and ```action_on_failure``` as options to ```HiveJob```.
+ Added integration tests to ```HiveJob```.

### 1.1

+ Added ```HiveJob```, a simplified way to launch basic Hive job flows.
+ Added HISTORY.

### 1.0.1

+ Added LICENSE.

### 1.0

+ Released!
