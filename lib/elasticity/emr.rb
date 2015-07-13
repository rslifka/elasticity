module Elasticity

  class EMR

    attr_reader :aws_request

    def initialize(aws_access_key_id=nil, aws_secret_access_key=nil, options = {})
      @aws_request = Elasticity::AwsSession.new(aws_access_key_id, aws_secret_access_key, options)
    end

    # Adds a new group of instances to the specified jobflow.  Elasticity maps a
    # more Ruby-like syntax to the Amazon options.  An exhaustive hash follows although
    # not all of these options are required (or valid!) at once.  Please see the
    # EMR docs for details although even then you're going to need to experiment :)
    #
    #   instance_group_config = {
    #     :bid_price => 5,
    #     :market => "SPOT",
    #     :name => "Go Canucks Go!",
    #     :instance_count => 1,
    #     :instance_role => "TASK",
    #     :instance_type => "m1.small"
    #   }
    #
    # add_instance_groups takes an array of {}.  Returns an array of the instance IDs
    # that were created by the specified configs.
    #
    #   ["ig-2GOVEN6HVJZID", "ig-1DU9M2UQMM051", "ig-3DZRW4Y2X4S", ...]
    def add_instance_groups(jobflow_id, instance_group_configs)
      params = {
        :operation => 'AddInstanceGroups',
        :job_flow_id => jobflow_id,
        :instance_groups => instance_group_configs
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
      JSON.parse(aws_result)['InstanceGroupIds']
    end

    # Add a step (or steps) to the specified job flow.
    #
    #   emr.add_jobflow_step("j-123", [
    #     {
    #       :action_on_failure => "TERMINATE_JOB_FLOW",
    #       :hadoop_jar_step => {
    #         :args => [
    #           "s3://elasticmapreduce/libs/pig/pig-script",
    #             "--base-path",
    #             "s3://elasticmapreduce/libs/pig/",
    #             "--install-pig"
    #         ],
    #         :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
    #       },
    #       :name => "Setup Pig"
    #     }
    #   ])
    def add_jobflow_steps(jobflow_id, steps_config)
      params = {
        :operation => 'AddJobFlowSteps',
        :job_flow_id => jobflow_id,
        :steps => steps_config
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Sets the specified tags on all instances in the specified jobflow
    #
    #   emr.add_tags('j-123', [{:key => 'key1', :value => 'value1'}, {:key => 'key_only2'}])
    #
    # See http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_AddTags.html
    def add_tags(jobflow_id, tags)
      params = {
        :operation => 'AddTags',
        :resource_id => jobflow_id,
        :tags => tags
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Provides details about the specified jobflow
    #
    #   emr.describe_cluster('j-123')
    #
    # http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_DescribeCluster.html
    def describe_cluster(jobflow_id)
      params = {
        :operation => 'DescribeCluster',
        :cluster_id => jobflow_id,
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
      JSON.parse(aws_result)
    end

    # List the instance groups in the specified jobflow
    #
    #   emr.list_instance_groups('j-123')
    #
    # http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_ListInstanceGroups.html
    def list_instance_groups(jobflow_id)
      params = {
        :operation => 'ListInstanceGroups',
        :cluster_id => jobflow_id,
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
      JSON.parse(aws_result)
    end

    # List the bootstrap actions in the specified jobflow
    #
    #   emr.list_bootstrap_actions('j-123')
    #
    # http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_ListBootstrapActions.html
    def list_bootstrap_actions(jobflow_id)
      params = {
        :operation => 'ListBootstrapActions',
        :cluster_id => jobflow_id,
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
      JSON.parse(aws_result)
    end

    # Set the number of instances in the specified instance groups to the
    # specified counts.  Note that this modifies the *request* count, which
    # is not the same as the *running* count.  I.e. you request instances
    # and then wait for them to be created.
    #
    # Takes a {} of instance group IDs => desired instance count.
    #
    #   {"ig-1" => 40, "ig-2" => 5, ...}
    def modify_instance_groups(instance_group_config)
      params = {
        :operation => 'ModifyInstanceGroups',
        :instance_groups => instance_group_config.map { |k, v| {:instance_group_id => k, :instance_count => v} }
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Remove the specified tags on all instances in the specified jobflow
    #
    #   emr.remove_tags('j-123', ['key1','key_only2'])
    #
    # See http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_RemoveTags.html
    def remove_tags(jobflow_id, keys)
      params = {
        :operation => 'RemoveTags',
        :resource_id => jobflow_id,
        :tag_keys => keys
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Start a job flow with the specified configuration.  This is a very thin
    # wrapper around the AWS API, so in order to use it directly you'll need
    # to have the PDF API reference handy, which can be found here:
    #
    # http://awsdocs.s3.amazonaws.com/ElasticMapReduce/20090331/emr-api-20090331.pdf
    #
    # Here is a sample job flow configuration that should help.  This job flow
    # starts by installing Pig then running a Pig script.  It is based off of the
    # Pig demo script from Amazon.
    #
    #   emr.run_job_flow({
    #     :name => "Elasticity Test Flow (EMR Pig Script)",
    #     :instances => {
    #       :ec2_key_name => "sharethrough-dev",
    #       :hadoop_version => "0.20",
    #       :instance_count => 2,
    #       :master_instance_type => "m1.small",
    #       :placement => {
    #         :availability_zone => "us-east-1a"
    #       },
    #       :slave_instance_type => "m1.small",
    #     },
    #     :steps => [
    #       {
    #         :action_on_failure => "TERMINATE_JOB_FLOW",
    #         :hadoop_jar_step => {
    #           :args => [
    #             "s3://elasticmapreduce/libs/pig/pig-script",
    #               "--base-path",
    #               "s3://elasticmapreduce/libs/pig/",
    #               "--install-pig"
    #           ],
    #           :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
    #         },
    #         :name => "Setup Pig"
    #       },
    #         {
    #           :action_on_failure => "TERMINATE_JOB_FLOW",
    #           :hadoop_jar_step => {
    #             :args => [
    #               "s3://elasticmapreduce/libs/pig/pig-script",
    #                 "--run-pig-script",
    #                 "--args",
    #                 "-p",
    #                 "INPUT=s3n://elasticmapreduce/samples/pig-apache/input",
    #                 "-p",
    #                 "OUTPUT=s3n://slif-elasticity/pig-apache/output/2011-04-19",
    #                 "s3n://elasticmapreduce/samples/pig-apache/do-reports.pig"
    #             ],
    #             :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
    #           },
    #           :name => "Run Pig Script"
    #         }
    #     ]
    #   })
    def run_job_flow(job_flow_config)
      params = {
        :operation => 'RunJobFlow',
      }.merge!(job_flow_config)
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
      JSON.parse(aws_result)['JobFlowId']
    end

    # Enabled or disable "termination protection" on the specified job flows.
    # Termination protection prevents a job flow from being terminated by a
    # user initiated action, although the job flow will still terminate
    # naturally.
    #
    # Takes an [] of job flow IDs.
    #
    #   ["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5", ...]
    def set_termination_protection(jobflow_ids, protection_enabled=true)
      params = {
        :operation => 'SetTerminationProtection',
        :termination_protected => protection_enabled,
        :job_flow_ids => jobflow_ids
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Whether or not all IAM users in this account can access the job flows.
    #
    # Takes an [] of job flow IDs.
    #
    #   ["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5", ...]
    #
    # http://docs.aws.amazon.com/ElasticMapReduce/latest/API/API_SetVisibleToAllUsers.html
    def set_visible_to_all_users(jobflow_ids, visible=true)
      params = {
        :operation => 'SetVisibleToAllUsers',
        :visible_to_all_users => visible,
        :job_flow_ids => jobflow_ids
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Terminate the specified jobflows.  Amazon does not define a return value
    # for this operation, so you'll need to poll to see the state of the jobflow.
    #
    # Takes an [] of job flow IDs.
    #
    #   ["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5", ...]
    def terminate_jobflows(jobflow_ids)
      params = {
        :operation => 'TerminateJobFlows',
        :job_flow_ids => jobflow_ids
      }
      aws_result = @aws_request.submit(params)
      yield aws_result if block_given?
    end

    # Pass the specified params hash directly through to the AWS request URL.
    # Use this if you want to perform an operation that hasn't yet been wrapped
    # by Elasticity or you just want to see the response XML for yourself :)
    def direct(params)
      @aws_request.submit(params)
    end

    def ==(other)
      return false unless other.is_a? EMR
      return false unless @aws_request == other.aws_request
      true
    end

  end

end
