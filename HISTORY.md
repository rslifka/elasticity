## 6.0.8 - February 22, 2016

- Including PR [#126](https://github.com/rslifka/elasticity/pull/126) - "Add support for additional security groups".  Thank you [@alistair](https://github.com/alistair)!

## 6.0.7 - February 1, 2016

- Including PR [#125](https://github.com/rslifka/elasticity/pull/125) - "AMI 4.x support".  Thank you [@fblundun](https://github.com/fblundun)!

## 6.0.6 - January 29, 2016

- Including PR [#120](https://github.com/rslifka/elasticity/pull/120) - "EMR Applications and support for release_label".  Thank you [@robert2d](https://github.com/robert2d)!

## 6.0.5 - August 28, 2015

- Including PR [#119](https://github.com/rslifka/elasticity/pull/119) - "Error handling for API rate limiting".  Thank you [@robert2d](https://github.com/robert2d)!

## 6.0.4 - August 3, 2015

- Including PR [#118](https://github.com/rslifka/elasticity/pull/118) - "jobflow ids must be passed as an array to AWS".  Thank you [@robert2d](https://github.com/robert2d)!

## 6.0.3 - July 24, 2015

- Including PR [#116](https://github.com/rslifka/elasticity/pull/116) - "Allow jobflow_id to be accessed after run".  Thank you [@robert2d](https://github.com/robert2d)!

## 6.0.2 - July 20, 2015

- Including PR [#111](https://github.com/rslifka/elasticity/pull/111) - "Handle steps status that hasn't run yet".  Thank you [@robert2d](https://github.com/robert2d)!
- Including PR [#112](https://github.com/rslifka/elasticity/pull/112) - "Parse Dates when step/cluster still starting".  Thank you [@robert2d](https://github.com/robert2d)!
- Including PR [#113](https://github.com/rslifka/elasticity/pull/113) - "Add job flow steps remove extra steps key".  Thank you [@robert2d](https://github.com/robert2d)!
- Including PR [#114](https://github.com/rslifka/elasticity/pull/114) - "Allow tags to be set on runJobFlow".  Thank you [@robert2d](https://github.com/robert2d)!

## 6.0.1 - July 19, 2015

- Including PR [#110](https://github.com/rslifka/elasticity/pull/110) - "Send bid price as string to aws api".  Thank you [@robert2d](https://github.com/robert2d)!

## 6.0 - July 17, 2015

Amazon is in the process of transitioning from the notion of "Job Flows" to "Clusters" and is updating their APIs as such.  You've already seen this in the EMR web UI as all mentions of "job flows" are gone and now you create "Clusters".

On the API side, all of the newer commands take `cluster_id` rather than `job_flow_id`.  On the API submission side, they are transitioning from a 'flat' structure to a nested JSON structure requiring no transformation. Finally, XML is all gone and commands return JSON (i.e. no more Nokogiri as a dependency).

They've also begun deprecating APIs, starting with `DescribeJobFlows`.  Given the sweeping set of changes, a major release was deemed appropriate.

- [#88](https://github.com/rslifka/elasticity/issues/88) - Removed support for deprecated `DescribeJobFlows`. 
- [#89](https://github.com/rslifka/elasticity/issues/89) - Add support for `AddTags`.
- [#90](https://github.com/rslifka/elasticity/issues/90) - Add support for `RemoveTags`.
- [#91](https://github.com/rslifka/elasticity/issues/91) - Add support for `SetVisibleToAllUsers`.
- [#92](https://github.com/rslifka/elasticity/issues/92) - Add support for `ListSteps`.
- [#93](https://github.com/rslifka/elasticity/issues/93) - Add support for `ListInstances`.
- [#94](https://github.com/rslifka/elasticity/issues/94) - Add support for `ListInstanceGroups`.
- [#95](https://github.com/rslifka/elasticity/issues/95) - Add support for `ListClusters`.
- [#96](https://github.com/rslifka/elasticity/issues/96) - Add support for `ListBootstrapActions`.
- [#97](https://github.com/rslifka/elasticity/issues/97) - Add support for `DescribeCluster`.
- [#98](https://github.com/rslifka/elasticity/issues/98) - Add support for `DescribeStep`.
- [#101](https://github.com/rslifka/elasticity/issues/101) - Fix plurality of `TerminateJobFlows`; now requires an array of IDs to terminate.
- [#102](https://github.com/rslifka/elasticity/issues/102) - Simplify interface to `AddJobFlowSteps`; no longer require extraneous `:steps => []`.
- [#104](https://github.com/rslifka/elasticity/issues/104) - Expose return value from `AddJobFlowSteps`.
- [#105](https://github.com/rslifka/elasticity/issues/105) - `JobFlow#status` has been removed in favour of `JobFlow#cluster_status` and `JobFlow#cluster_step_status`.
- [#107](https://github.com/rslifka/elasticity/issues/107) - Add support for temporary credentials via `Elasticity.configure`.
- [#109](https://github.com/rslifka/elasticity/issues/109) - Credential specification relocated to `Elasticity.configure`.

## 5.0.3 - July 8, 2015

- Fix for issue [#86](https://github.com/rslifka/elasticity/issues/86).

## 5.0.2 - April 27, 2015

- Fix for issue [#83](https://github.com/rslifka/elasticity/issues/83), `elasticity` has now transitioned to the AWS [Signature Version 4 Signing Process](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).
- Removed the ability to create insecure (HTTP) connections to the EMR endpoints.

## 5.0.1 - April 12, 2015

- Bear with me here :)  Backmerged into 4.0.4 to add [IAM Service Role support](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-iam-roles-creatingroles.html) per @alexanderdean.  As part of the forward merge, bumping the version to trigger an update.

## 5.0 - March 28, 2015

- Major version bump as there are language support implications.
- Now supporting only the latest version of the 2.x minors (e.g. 2.0.x, 2.1.x, etc.) versus specific minor-minor releases.  This was an oversight on my part in how I both configured Travis and communicated support for the 2.x line.
- Removed support for Ruby 1.9.3 as it has been [unsupported since 2/23/2015](https://www.ruby-lang.org/en/news/2014/01/10/ruby-1-9-3-will-end-on-2015/).
- Removed "support" for JRuby.  It was in poor form that I originally claimed to support JRuby as I do not have the time to dedicate to such an endeavor.  Compatibility is merely coincidental and it would not be responsible for me to continue communicating ongoing support when that is not my intention.  Apologies to those this may inconvenience.

## 4.0.5 - April 9, 2015

- Thanks to @alexanderdean, pull request [#82](https://github.com/rslifka/elasticity/pull/82) adds support for profile roles.

## 4.0.4 - November 20, 2014

- Thanks to @jshafton, pull request [#79](https://github.com/rslifka/elasticity/pull/79) adds support for job flow roles.

## 4.0.3 - November 12, 2014

- Thanks to @ilyakava, pull request [#78](https://github.com/rslifka/elasticity/pull/78) fixes a bug in the "wait for completion" feature.

## 4.0.2 - September 20, 2014

- Thanks to @jshafton, now with support for Ganglia!

## 4.0.1 - September 4, 2014

- Now tracking the Master Instance ID and Created At timestamp for job flows and steps, via @AuraBorea (Thanks!) [#73](https://github.com/rslifka/elasticity/issues/73).

## 4.0 - May 21, 2014

- Fix for issue [#69](https://github.com/rslifka/elasticity/issues/69).  The AWS region was previously being derived from the placement.  With the advent of VPC/subnet IDs being set, placement is not always relevant (as the VPC subnet ID implicitly defines a placement).  Since region cannot be derived it is now available directly on `JobFlow`.
- Fix for issue [#79](https://github.com/rslifka/elasticity/issues/70).  Removing the ability to set the now deprecated Hadoop version.  It is now set via specifying the AMI version.  See the [EMR docs](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-plan-hadoop-version.html) for more details.
- Building against JRuby 1.8.  While I don't necessarily have the resources to optimize for JRuby compatibility (given that I know next to nothing about it :) I'll use this as a canary to tackle any low-hanging issues that may arise.

## 3.0.4 - April 30, 2014

- Fix for issues [#65](https://github.com/rslifka/elasticity/issues/65) and [#66](https://github.com/rslifka/elasticity/issues/66).

## 3.0.3 - April 10, 2014

- Fix for issues [#63](https://github.com/rslifka/elasticity/issues/63) and [#64](https://github.com/rslifka/elasticity/issues/64).

## 3.0.2 - March 26, 2014

- Second go at a fix for [Issue #60](https://github.com/rslifka/elasticity/issues/60), "Specifying a VPC subnet does not work" as placement and subnet cannot both be specified.

## 3.0.1 - March 26, 2014

- Fix for [Issue #60](https://github.com/rslifka/elasticity/issues/60), "Specifying a VPC subnet does not work".
- Add support for Ruby 2.1.0 and 2.1.1.

## 3.0 - February 15, 2014

- Major/minor bump because of breaking API changes to `Elasticity::BootstrapAction` due to [Issue #55](https://github.com/rslifka/elasticity/issues/55).  After spending some time deprecating, I realized I don't have the code bandwidth to do it in a way that I would be happy with.  Move fast and break things ;)
- Dev update: Added `Elasticity::EMR#describe_jobflow_xml` to assist in job flow debugging.

## 2.7 - December 4, 2013

- `Elasticity::S3DistCp` and `Elasticity::ScriptStep` added to provide easy access to remote copying and arbitrary script execution.
- `Elasticity::EMR` can now autodetect AWS credentials.
- Baseline support now is now 1.9.3-p484.  Dropped support for Ruby 1.9.2 as it was [EOL on 2013/06/01](http://bugs.ruby-lang.org/projects/ruby/wiki/ReleaseEngineering).
- Dev update: No longer using `guard-rspec`.
- Dev update: Added `unf` as an explicit dependency as `fog` no longer includes it since it's AWS-only.

## 2.6 - August 17, 2013

+ Added debugging support via `JobFlow#enable_debugging`.  Note that this requires `JobFlow#log_uri` to be set.
+ Added job flow completion polling via `JobFlow#wait_for_completion`.
+ Added testing to support Ruby 2.0.
+ Removed support for REE and 1.8.7 as these are now unsupported versions of Ruby.  Common strategy in the Ruby community has been to only perform a minor version bump in this case; Elasticity is following suit.
+ Now specifying minor versions in the gemspec.  With the release of Ruby 2.0, I'm anticipating breaking changes coming to many gems, and hoping that this mitigates those effects.
+ Dev update: guard-rspec added.
+ Dev update: All development dependencies now require Ruby >= 1.9.2.
+ Dev update: Latest version of Ruby 1.9.2 (p320).
+ Dev update: Migrated from .rvmrc => .ruby-version and .ruby-gemset.

## 2.5.6 - February 9, 2013

+ Pull request from [Aaron Olson](https://github.com/airolson), removing requirement that a ```JobFlow``` has steps before running.
+ Updating development to ruby-1.9.3-p385.

## 2.5.5 - February 3, 2013

+ Pull request from [Aaron Olson](https://github.com/airolson), adding ```StreamingStep#arguments```.

## 2.5.4 - February 1, 2013

+ Pull request from [Aaron Olson](https://github.com/airolson), adding ```JobFlowStatus#normalized_instance_hours```.

## 2.5.3 - January 16, 2013

+ Added ```#visible_to_all_users``` to ```JobFlow```.  Thanks to [dstumm](https://github.com/dstumm) for the contribution!
+ Added ```#ended_at``` to ```JobFlowStatus```.
+ Added ```#duration``` calculated field to ```JobFlowStatus```.

## 2.5.2 - November 29, 2012

+ Configuration of Hive installations via ```hive_site``` is now supported.  See the README.md for details.

## 2.5.1 - November 28, 2012

+ When ```JobFlow#placement``` is specified, instances are created in that availability zone.  Previously, this setting was only used to derive the EMR API endpoint to connect to (i.e. the region).
+ Updated development dependencies.

## 2.5 - September 29, 2012

+ ```SyncToS3``` supports S3 region specification.
+ ```SyncToS3#sync``` supports being called with both files and directories.

## 2.4 - September 1, 2012

+ ```SyncToS3``` added to enable one-way asset synchronization.
+ Generic bootstrap actions are now supported via ```BootstrapAction```.
+ If you have several Hadoop bootstrap actions (15 is the current EMR limit), store all of your Hadoop configuration options in a file, ship it up with ```SyncToS3``` and use the new ```HadoopFileBootstrapAction``` to point at that file.
+ If no parameters are passed to ```JobFlow.new```, it will use the standard AWS environment variables to lookup the access and secret keys - ```AWS_ACCESS_KEY_ID``` and ```AWS_SECRET_ACCESS_KEY```.
+ New dependencies: [fog](https://github.com/fog/fog) (S3 access), [fakefs](https://github.com/defunkt/fakefs) (filesystem stubbing - development only), [timecop](https://github.com/jtrupiano/timecop) (freezing and manipulating time - development only).

## 2.3.1 - August 23, 2012

+ Birthday release! ;)
+ Bumped the default version of Hadoop to 1.0.3.
+ Amazon now requires the ```--hive-versions``` argument when installing Hive (thanks to Johannes Wuerbach).
+ ```JobFlowStatus#master_public_dns_name``` is now available (thanks to Johannes Wuerbach).

## 2.3 - July 28, 2012

+ ```JobFlow``` now supports specifying availbility zone instance specification via ```JobFlow#placement=```.
+ ```JobFlow::from_jobflow_id``` now supports region specification so that jobs created in regions other than us-east-1 can be recreated.

## 2.2 - July 23, 2012

+ Hadoop streaming jobs are now supported via ```Elasticity::StreamingStep```.

## 2.1.1 - July 22, 2012

+ ```JobFlow::from_jobflow_id``` factory method added so that you can operate on running job flows (add steps, shutdown, status, etc.) that you didn't start in the same Ruby instance.
+ Updated to rspec-2.11.

## 2.1 - July 7, 2012

+ TASK instance group support added.
+ SPOT instance support added for all instance group types. 
+ Removed name of jar from default name of ```CustomJarStep``` since the AWS UI already calls it out in a separate column when looking at job flow steps.

## 2.0 - June 26, 2012

2.0 is a rewrite of the simplified API after a year's worth of daily use at [Sharethrough](http://www.sharethrough.com/).  We're investing heavily in our data processing infrastucture and many Elasticity feature ideas have come from those efforts.

In order to move more quickly and support interesting features like a command-line interface, configuration-file-based launching, keep-alive clusters and more - a remodeling of the simplified API was done.  This is going to result in breaking changes to the API, hence the bump to 2.0.  I hope that most of you were using ```gem 'elasticity', '~> 1.5'``` in your Gemfile :)

#### API Changes

+ The ```SimpleJob```-based API has been removed in favour of a more modular step-based approach using the "job flow" and "step" vernacular, in line with Amazon's own language.  If you're familiar with the AWS UI, using Elasticity will be a bit more straightforward.
+ The functionality provided by ```JobFlow``` and ```JobFlowStep``` has been transitioned to ```JobFlowStatus``` and ```JobFlowStatusStep``` respectively, clearing the path for use of ```JobFlow``` and ```JobFlowStep``` in job submission.

#### New Features!

+ When submitting jobs via ```JobFlow``` API, it is now possible to specify the version of the AMI, whether or not the cluster is keep-alive, and the subnet ID (for launching into a VPC).  Keep in mind that AWS will error out if you specify an unsupported combination of AMI and Hadoop version.
+ The default version of Hadoop in ```JobFlow``` is now 0.20.205.  The previous default was 0.20 in case you'd like to set it yourself.
+ It is now possible to name Hadoop bootstrap actions, making it easier to understand the actions when looking in the AWS UI after a job is submitted.

#### Under The Hood

+ AWS requests are now POSTs (thanks to [Menno van der Sman](https://github.com/menno)) in order to avoid server-imposed GET request size limits.  Rather than maintain two separate code paths for GET and POST, we decided to only support POST as there is no reason to support both.
+ Drastic simplification of the testing around EMR submission, reducing LoC (however important that metric is you :) and complexity by ~50%.
+ Development dependency updates: updated to ruby-1.9.3-p194 and rspec-2.10.  Removed dependency on VCR and WebMock (no longer using either of these).

## 1.5 - March 5, 2012

+ Added support for Hadoop bootstrap actions to all job types (Pig, Hive and Custom Jar).
+ Added support for REE 1.8.7-2011.12, Ruby 1.9.2 and 1.9.3.
+ Updated to the latest versions of all development dependencies (notably VCR 2).

## 1.4.1 - December 17, 2011

+ Added ```Elasticity::EMR#describe_jobflow("jobflow_id")``` for describing a specific job.  If you happen to run hundreds of EMR jobs, this makes retrieving jobflow status much faster than using ```Elasticity::EMR#describe_jobflowS``` which pulls down and parses XML status for hundreds of jobs.

## 1.4 - December 9, 2011

+ Added ```Elasticity::CustomJarJob``` for launching "Custom Jar" jobs.

## 1.3.1 - November 16, 2011

+ Explicitly requiring 'time' (only a problem if you aren't running from within a Rails environment).
+ ```Elasticity::JobFlow``` now exposes ```last_state_change_reason```.

## 1.3 - October 10, 2011

This release primarily contains contributions from Wouter Broekhof

+ The default mode of communication is now via HTTPS.
+ ```Elasticity::AwsRequest``` new option ```:secure => true|false``` (whether to use HTTPS).
+ ```Elasticity::AwsRequest``` new option ```:region => eu-west-1|...``` (which region to run the EMR job).
+ ```Elasticity::EMR#describe_jobflows``` now accepts additional params for filtering the jobflow query (see docs).

## 1.2.2 - May 10, 2011

+ ```HiveJob``` and ```PigJob``` now support configuring Hadoop options via ```#add_hadoop_bootstrap_action()```.

## 1.2.1 - May 7, 2011

+ Shipping up E_PARALLELS Pig variable with each invocation; reasonable default value for PARALLEL based on the number and type of instances configured.

## 1.2 - May 4, 2011

+ Added ```PigJob```!

## 1.1.1 - April 25, 2011

+ ```HiveJob``` critical bug fixed, now it works :)
+ Added ```log_uri``` and ```action_on_failure``` as options to ```HiveJob```.
+ Added integration tests to ```HiveJob```.

## 1.1 - April 24, 2011

+ Added ```HiveJob```, a simplified way to launch basic Hive job flows.
+ Added HISTORY.

## 1.0.1 - April 22, 2011

+ Added LICENSE.

## 1.0 - April 22, 2011

+ Released!
