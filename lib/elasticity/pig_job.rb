module Elasticity

  class PigJob < Elasticity::SimpleJob

    # Automatically passed as Pig argument E_PARALLELS
    attr_reader :parallels

    def initialize(aws_access_key_id, aws_secret_access_key)
      super
      @name = "Elasticity Pig Job"
      @parallels = calculate_parallels
    end

    def instance_count=(num_instances)
      if num_instances < 2
        raise ArgumentError, "Instance count cannot be set to less than 2 (requested #{num_instances})"
      end
      @instance_count = num_instances
      @parallels = calculate_parallels
    end

    def slave_instance_type=(instance_type)
      @slave_instance_type = instance_type
      @parallels = calculate_parallels
    end

    # Run the specified Pig script with the specified variables.
    #
    #   pig = Elasticity::PigJob.new("access", "secret")
    #   jobflow_id = pig.run('s3n://slif-pig-test/test.pig', {
    #     'SCRIPTS' => 's3n://slif-pig-test/scripts',
    #     'OUTPUT'  => 's3n://slif-pig-test/output',
    #     'XREFS'   => 's3n://slif-pig-test/xrefs'
    #   })
    #
    # The variables are accessible within your Pig scripts by using the
    # standard ${NAME} syntax.
    def run(pig_script, pig_variables={})
      script_arguments = ["s3://elasticmapreduce/libs/pig/pig-script", "--run-pig-script", "--args"]
      pig_variables.keys.sort.each do |variable_name|
        script_arguments.concat(["-p", "#{variable_name}=#{pig_variables[variable_name]}"])
      end
      script_arguments.concat(["-p", "E_PARALLELS=#{@parallels}"])
      script_arguments << pig_script
      jobflow_config = {
        :name => @name,
        :instances => {
          :ec2_key_name => @ec2_key_name,
          :hadoop_version => @hadoop_version,
          :instance_count => @instance_count,
          :master_instance_type => @master_instance_type,
          :slave_instance_type => @slave_instance_type,
        },
        :steps => [
          {
            :action_on_failure => "TERMINATE_JOB_FLOW",
            :hadoop_jar_step => {
              :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
              :args => [
                "s3://elasticmapreduce/libs/pig/pig-script",
                  "--base-path", "s3://elasticmapreduce/libs/pig/",
                  "--install-pig"
              ],
            },
            :name => "Setup Pig"
          },
            {
              :action_on_failure => @action_on_failure,
              :hadoop_jar_step => {
                :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
                :args => script_arguments,
              },
              :name => "Run Pig Script"
            }
        ]
      }

      jobflow_config.merge!(:log_uri => @log_uri) if @log_uri
      jobflow_config.merge!(get_bootstrap_actions)

      @emr.run_job_flow(jobflow_config)
    end

    private

    # Calculate a common-sense default value of PARALLELS using the following
    # formula from the Pig Cookbook:
    #
    #   <num machines> * <num reduce slots per machine> * 0.9
    #
    # With the following reducer configuration (from an AWS forum post):
    #
    #   m1.small   1
    #   m1.large   2
    #   m1.xlarge  4
    #   c1.medium  2
    #   c1.xlarge  4
    def calculate_parallels
      reduce_slots = case @slave_instance_type
        when "m1.small" then 1
        when "m1.large" then 2
        when "m1.xlarge" then 4
        when "c1.medium" then 2
        when "c1.xlarge" then 4
        else 1
      end
      ((@instance_count - 1).to_f * reduce_slots.to_f * 0.9).ceil
    end
    
  end
  
end