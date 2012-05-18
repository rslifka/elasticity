module Elasticity

  class SimpleJob

    attr_accessor :action_on_failure
    attr_accessor :aws_access_key_id
    attr_accessor :aws_secret_access_key
    attr_accessor :ec2_key_name
    attr_accessor :name
    attr_accessor :hadoop_version
    attr_accessor :instance_count
    attr_accessor :log_uri
    attr_accessor :master_instance_type
    attr_accessor :slave_instance_type

    def initialize(aws_access_key_id, aws_secret_access_key)
      @action_on_failure = "TERMINATE_JOB_FLOW"
      @aws_access_key_id = aws_access_key_id
      @aws_secret_access_key = aws_secret_access_key
      @ec2_key_name = "default"
      @hadoop_version = "0.20"
      @instance_count = 2
      @master_instance_type = "m1.small"
      @name = "Elasticity Job"
      @slave_instance_type = "m1.small"

      @bootstrap_actions = []
      @emr = Elasticity::EMR.new(aws_access_key_id, aws_secret_access_key)
    end

    def add_hadoop_bootstrap_action(option, value)
      @bootstrap_actions << [option, value]
    end

    def run
      @emr.run_job_flow(jobflow_config)
    end

    private

    def jobflow_config
      config = jobflow_preamble
      config.merge!(:steps => jobflow_steps)
      config.merge!(:log_uri => @log_uri) if @log_uri
      config.merge!(:bootstrap_actions => jobflow_bootstrap_actions) unless @bootstrap_actions.empty?
      config
    end

    def jobflow_preamble
      {
        :name => @name,
        :instances => {
          :ec2_key_name => @ec2_key_name,
          :hadoop_version => @hadoop_version,
          :instance_count => @instance_count,
          :master_instance_type => @master_instance_type,
          :slave_instance_type => @slave_instance_type,
        },
      }
    end

    def jobflow_bootstrap_actions
      actions = []
      @bootstrap_actions.each do |action|
        actions << jobflow_bootstrap_action(action[0], action[1])
      end
      actions
    end

    def jobflow_bootstrap_action(option, value)
      {
        :name => "Elasticity Bootstrap Action (Configure Hadoop)",
        :script_bootstrap_action => {
          :path => "s3n://elasticmapreduce/bootstrap-actions/configure-hadoop",
          :args => [option, value]
        }
      }
    end

  end

end