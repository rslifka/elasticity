### 2.0

+ Added support for launching SimpleJobS on persistent clusters via Cluster.
+ Refactored SimpleJob implementation and broke backwards compatibility with all SimpleJobS (Hive, Pig, Custom).  Have a look at the README.
+ Dependency updates: ruby-1.9.3-p194, rspec-2.10.

### 1.5

+ Added support for Hadoop bootstrap actions to all job types (Pig, Hive and Custom Jar).
+ Added support for REE 1.8.7-2011.12, Ruby 1.9.2 and 1.9.3.
+ Updated to the latest versions of all development dependencies (notably VCR 2).

### 1.4.1

+ Added Elasticity::EMR#describe_jobflow("jobflow_id") for describing a specific job.  If you happen to run hundreds of EMR jobs, this makes retrieving jobflow status much faster than using Elasticity::EMR#describe_jobflowS which pulls down and parses XML status for hundreds of jobs.

### 1.4

+ Added Elasticity::CustomJarJob for launching "Custom Jar" jobs.

### 1.3.1

+ Explicitly requiring 'time' (only a problem if you aren't running from within a Rails environment).
+ Elasticity::JobFlow now exposes last_state_change_reason.

### 1.3 (Contributions from Wouter Broekhof)

+ The default mode of communication is now via HTTPS.
+ Elasticity::AwsRequest new option :secure => true|false (whether to use HTTPS).
+ Elasticity::AwsRequest new option :region => eu-west-1|... (which region to run the EMR job).
+ Elasticity::EMR#describe_jobflows now accepts additional params for filtering the jobflow query (see docs).

### 1.2.2

+ HiveJob and PigJob now support configuring Hadoop options via .add_hadoop_bootstrap_action().

### 1.2.1

+ Shipping up E_PARALLELS Pig variable with each invocation; reasonable default value for PARALLEL based on the number and type of instances configured.

### 1.2

+ Added PigJob!

### 1.1.1

+ HiveJob critical bug fixed, now it works :)
+ Added log_uri and action_on_failure as options to HiveJob.
+ Added integration tests to HiveJob.

### 1.1

+ Added HiveJob, a simplified way to launch basic Hive job flows.
+ Added HISTORY.

### 1.0.1

+ Added LICENSE.

### 1.0

+ Released!
